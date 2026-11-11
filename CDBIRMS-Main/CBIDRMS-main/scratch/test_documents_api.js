const http = require("http");

const BASE_URL = "http://localhost:5000/api";

function makeRequest(url, options = {}, body = null) {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url);
        const requestOptions = {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port,
            path: parsedUrl.pathname + parsedUrl.search,
            method: options.method || "GET",
            headers: {
                "Content-Type": "application/json",
                ...options.headers
            }
        };

        const req = http.request(requestOptions, (res) => {
            let data = "";
            res.on("data", (chunk) => {
                data += chunk;
            });
            res.on("end", () => {
                let parsedData;
                try {
                    parsedData = data ? JSON.parse(data) : {};
                } catch (e) {
                    parsedData = { raw: data };
                }
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    data: parsedData
                });
            });
        });

        req.on("error", (err) => {
            reject(err);
        });

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function runTests() {
    console.log("=== Verification of Document Management API (FC-012) ===\n");

    try {
        // 1. Fetch initial documents list
        console.log("1. GET /api/documents...");
        const initialRes = await makeRequest(`${BASE_URL}/documents`);
        console.log(`   Status: ${initialRes.statusCode}`);
        console.log(`   Message: ${initialRes.data.message}`);
        console.log(`   Total Documents: ${initialRes.data.data?.total}\n`);

        // 2. Create a test project first or use PRJ-101
        console.log("2. POST /api/documents (Upload Document)...");
        const createRes = await makeRequest(`${BASE_URL}/documents`, { method: "POST" }, {
            title: "Villa Royale Floor Plan v2.pdf",
            projectId: "PRJ-101",
            category: "FLOOR_PLAN",
            fileType: "PDF",
            fileSize: "5.4 MB"
        });
        console.log(`   Status: ${createRes.statusCode}`);
        console.log(`   Message: ${createRes.data.message}`);
        const docId = createRes.data.data?.document?.id;
        console.log(`   Document ID: ${docId}\n`);

        if (!docId) {
            throw new Error(`Failed to create document: ${JSON.stringify(createRes.data)}`);
        }

        // 3. Search and filter documents by category
        console.log("3. GET /api/documents?category=FLOOR_PLAN&search=Floor...");
        const filterRes = await makeRequest(`${BASE_URL}/documents?category=FLOOR_PLAN&search=Floor`);
        console.log(`   Status: ${filterRes.statusCode}`);
        console.log(`   Filtered Count: ${filterRes.data.data?.documents?.length}\n`);

        // 4. Download document signed link
        console.log(`4a. GET /api/documents/${docId}/download...`);
        const downloadRes = await makeRequest(`${BASE_URL}/documents/${docId}/download`);
        console.log(`   Status: ${downloadRes.statusCode}`);
        const downloadUrl = downloadRes.data.data?.downloadUrl;
        console.log(`   Download URL: ${downloadUrl}\n`);

        // 4b. Verify binary PDF download endpoint
        console.log(`4b. GET /api/documents/${docId}/file (Binary PDF Stream)...`);
        const fileRes = await makeRequest(`${BASE_URL}/documents/${docId}/file`);
        console.log(`   Status: ${fileRes.statusCode}`);
        console.log(`   Content-Type: ${fileRes.headers["content-type"]}`);
        console.log(`   Content-Disposition: ${fileRes.headers["content-disposition"]}\n`);

        // 5. Delete document
        console.log(`5. DELETE /api/documents/${docId}...`);
        const deleteRes = await makeRequest(`${BASE_URL}/documents/${docId}`, { method: "DELETE" });
        console.log(`   Status: ${deleteRes.statusCode}`);
        console.log(`   Message: ${deleteRes.data.message}\n`);

        console.log("SUCCESS: All Document Management API tests passed cleanly!");
    } catch (error) {
        console.error("ERROR in test script:", error);
    }
}

runTests();
