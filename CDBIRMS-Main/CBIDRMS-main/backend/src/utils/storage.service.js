const fs = require("fs");
const path = require("path");
const { createClient } = require("@supabase/supabase-js");

let supabaseClient = null;

const getSupabaseClient = () => {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY;

    if (supabaseUrl && supabaseKey) {
        if (!supabaseClient) {
            supabaseClient = createClient(supabaseUrl, supabaseKey);
        }
        return supabaseClient;
    }
    return null;
};

/**
 * Upload design file to Supabase Storage or fallback to local disk storage.
 * Bucket: designs/
 * Path: designs/{projectId}/{designId}/{version}-{filename}
 */
const uploadDesignFile = async ({ projectId, designId, version, fileName, buffer, filePath, contentType }) => {
    const sanitizedFileName = path.basename(fileName).replace(/[^a-zA-Z0-9_.-]/g, "_");
    const storagePath = `${projectId}/${designId}/${version}-${sanitizedFileName}`;
    const supabase = getSupabaseClient();

    let fileBuffer = buffer;
    if (!fileBuffer && filePath && fs.existsSync(filePath)) {
        fileBuffer = fs.readFileSync(filePath);
    }

    if (supabase && fileBuffer) {
        try {
            const { data, error } = await supabase.storage
                .from("designs")
                .upload(storagePath, fileBuffer, {
                    contentType: contentType || "application/octet-stream",
                    upsert: false
                });

            if (error) {
                console.warn("[SUPABASE STORAGE WARNING] Upload error, falling back to local:", error.message);
            } else {
                const { data: signedData } = await supabase.storage
                    .from("designs")
                    .createSignedUrl(storagePath, 3600);

                return {
                    fileUrl: signedData?.signedUrl || `${process.env.SUPABASE_URL}/storage/v1/object/public/designs/${storagePath}`,
                    storagePath,
                    provider: "supabase"
                };
            }
        } catch (err) {
            console.warn("[SUPABASE STORAGE ERROR] Exception occurred, falling back to local:", err.message);
        }
    }

    // Local Disk Storage Fallback
    const localDir = path.join(__dirname, "../../../uploads/designs", projectId, designId);
    if (!fs.existsSync(localDir)) {
        fs.mkdirSync(localDir, { recursive: true });
    }

    const localFilePath = path.join(localDir, `${version}-${sanitizedFileName}`);
    if (fileBuffer) {
        fs.writeFileSync(localFilePath, fileBuffer);
    } else if (filePath && fs.existsSync(filePath)) {
        fs.copyFileSync(filePath, localFilePath);
    }

    const host = process.env.BACKEND_URL || `http://localhost:${process.env.PORT || 5000}`;
    const localUrl = `${host}/api/designs/${designId}/file`;

    return {
        fileUrl: localUrl,
        storagePath: localFilePath,
        provider: "local"
    };
};

/**
 * Generate a secure signed URL for downloading a design file.
 */
const getSignedDownloadUrl = async (design) => {
    const supabase = getSupabaseClient();
    const host = process.env.BACKEND_URL || `http://localhost:${process.env.PORT || 5000}`;
    const expiresAt = new Date(Date.now() + 3600 * 1000).toISOString();

    if (supabase && design.fileUrl && design.fileUrl.includes("supabase")) {
        try {
            // Extract relative storage path
            const parts = design.fileUrl.split("/designs/");
            if (parts.length > 1) {
                const relPath = parts[1].split("?")[0];
                const { data, error } = await supabase.storage
                    .from("designs")
                    .createSignedUrl(relPath, 3600);

                if (data?.signedUrl) {
                    return {
                        downloadUrl: data.signedUrl,
                        fileName: design.title,
                        expiresAt
                    };
                }
            }
        } catch (err) {
            console.warn("[SUPABASE STORAGE ERROR] Signed URL generation failed:", err.message);
        }
    }

    // Local file fallback download URL
    return {
        downloadUrl: `${host}/api/designs/${design.id}/file`,
        fileName: design.title.endsWith(".pdf") || design.title.endsWith(".png") || design.title.endsWith(".jpg") || design.title.endsWith(".jpeg") || design.title.endsWith(".dwg") || design.title.endsWith(".dxf")
            ? design.title
            : `${design.title}.${(design.fileType || "pdf").toLowerCase()}`,
        expiresAt
    };
};

module.exports = {
    uploadDesignFile,
    getSignedDownloadUrl
};
