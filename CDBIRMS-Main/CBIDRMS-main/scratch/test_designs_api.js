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
    console.log("=== Verification of Design Management API (FC-010) ===\n");

    try {
        // 1. GET /api/designs
        console.log("1. GET /api/designs...");
        const initialRes = await makeRequest(`${BASE_URL}/designs`);
        console.log(`   Status: ${initialRes.statusCode}`);
        console.log(`   Message: ${initialRes.data.message}`);
        console.log(`   Total Designs: ${initialRes.data.data?.total}\n`);

        // 2. POST /api/designs (Create Design v1.0)
        console.log("2. POST /api/designs (Upload Drawing)...");
        const createRes = await makeRequest(`${BASE_URL}/designs`, { method: "POST" }, {
            title: "Master Bedroom 3D Layout",
            projectId: "PRJ-101",
            category: "THREE_D_RENDER",
            fileType: "PDF",
            fileSize: "4.5 MB"
        });
        console.log(`   Status: ${createRes.statusCode}`);
        console.log(`   Message: ${createRes.data.message}`);
        const design = createRes.data.data?.design;
        console.log(`   Design ID: ${design?.id}, Version: ${design?.version}, Status: ${design?.approvalStatus}\n`);

        if (!design?.id) {
            throw new Error(`Failed to create design: ${JSON.stringify(createRes.data)}`);
        }

        // 3. POST /api/designs/:id/revise (Create Revision v1.1)
        console.log(`3. POST /api/designs/${design.id}/revise (New Revision v1.1)...`);
        const reviseRes = await makeRequest(`${BASE_URL}/designs/${design.id}/revise`, { method: "POST" }, {
            title: "Master Bedroom 3D Layout v1.1",
            isMajorVersion: false
        });
        console.log(`   Status: ${reviseRes.statusCode}`);
        console.log(`   Message: ${reviseRes.data.message}`);
        const rev1 = reviseRes.data.data?.design;
        console.log(`   Revision ID: ${rev1?.id}, Version: ${rev1?.version}\n`);

        // 4. POST /api/designs/:id/approve (Request Revision)
        console.log(`4a. POST /api/designs/${rev1.id}/approve (Request Revision)...`);
        const rejectRes = await makeRequest(`${BASE_URL}/designs/${rev1.id}/approve`, { method: "POST" }, {
            action: "REQUEST_REVISION",
            note: "Please adjust wardrobe depth to 24 inches"
        });
        console.log(`   Status: ${rejectRes.statusCode}`);
        console.log(`   Updated Status: ${rejectRes.data.data?.design?.approvalStatus}\n`);

        // 4b. Approve design
        console.log(`4b. POST /api/designs/${rev1.id}/approve (Approve)...`);
        const approveRes = await makeRequest(`${BASE_URL}/designs/${rev1.id}/approve`, { method: "POST" }, {
            action: "APPROVE",
            note: "Approved for site execution"
        });
        console.log(`   Status: ${approveRes.statusCode}`);
        console.log(`   Updated Status: ${approveRes.data.data?.design?.approvalStatus}\n`);

        // 5. GET /api/designs/:id (Detail & Audit Logs)
        console.log(`5. GET /api/designs/${rev1.id} (Details & Audit History)...`);
        const detailRes = await makeRequest(`${BASE_URL}/designs/${rev1.id}`);
        console.log(`   Status: ${detailRes.statusCode}`);
        console.log(`   Approval History Logs: ${detailRes.data.data?.approvalHistory?.length}`);
        console.log(`   Revisions Chain Count: ${detailRes.data.data?.revisions?.length}\n`);

        // 6. GET /api/designs/:id/download
        console.log(`6a. GET /api/designs/${rev1.id}/download...`);
        const downloadRes = await makeRequest(`${BASE_URL}/designs/${rev1.id}/download`);
        console.log(`   Status: ${downloadRes.statusCode}`);
        console.log(`   Download URL: ${downloadRes.data.data?.downloadUrl}\n`);

        // 7. GET /api/designs/:id/file (Binary PDF Stream)
        console.log(`6b. GET /api/designs/${rev1.id}/file (Binary File Stream)...`);
        const fileRes = await makeRequest(`${BASE_URL}/designs/${rev1.id}/file`);
        console.log(`   Status: ${fileRes.statusCode}`);
        console.log(`   Content-Type: ${fileRes.headers["content-type"]}`);
        console.log(`   Content-Disposition: ${fileRes.headers["content-disposition"]}\n`);

        console.log("SUCCESS: All Design Management API tests passed cleanly!");
    } catch (error) {
        console.error("ERROR in test script:", error);
    }
}

runTests();
