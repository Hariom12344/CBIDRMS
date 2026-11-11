const http = require("http");
const fs = require("fs");
const path = require("path");
const jwt = require(path.join(__dirname, "../backend/node_modules/jsonwebtoken"));

const JWT_SECRET = process.env.JWT_SECRET || "super-secret-jwt-key-idpms-2026";

// Create test JWT token for a given user
function makeToken(user) {
    return jwt.sign(
        {
            id: user.id,
            email: user.email,
            role: user.role,
            fullName: user.fullName,
            companyId: user.companyId || 1
        },
        JWT_SECRET,
        { expiresIn: "1h" }
    );
}

// Users from DB for testing exact permission rules
const users = {
    admin: { id: 19, email: "test_super_admin@idpms.com", role: "SUPER_ADMIN", fullName: "Test SUPER_ADMIN", companyId: 1 },
    pm: { id: 22, email: "test_project_manager@idpms.com", role: "PROJECT_MANAGER", fullName: "Test PROJECT_MANAGER", companyId: 1 },
    assignedDesigner: { id: 24, email: "test_designer@idpms.com", role: "DESIGNER", fullName: "Test DESIGNER", companyId: 1 },
    unassignedDesigner: { id: 60, email: "mayuragrwal07@gmail.com", role: "DESIGNER", fullName: "Unassigned Designer", companyId: 1 },
    supervisor: { id: 23, email: "test_site_supervisor@idpms.com", role: "SITE_SUPERVISOR", fullName: "Test SITE_SUPERVISOR", companyId: 1 },
    accountant: { id: 25, email: "test_accountant@idpms.com", role: "ACCOUNTANT", fullName: "Test ACCOUNTANT", companyId: 1 }
};

function httpRequest({ method, path: reqPath, headers = {}, body = null }) {
    return new Promise((resolve, reject) => {
        const req = http.request(
            {
                host: "localhost",
                port: 5000,
                method,
                path: reqPath,
                headers
            },
            (res) => {
                let data = "";
                res.on("data", (chunk) => (data += chunk));
                res.on("end", () => {
                    try {
                        const parsed = JSON.parse(data);
                        resolve({ status: res.statusCode, body: parsed });
                    } catch (e) {
                        resolve({ status: res.statusCode, body: data });
                    }
                });
            }
        );
        req.on("error", reject);
        if (body) {
            req.write(body);
        }
        req.end();
    });
}

function makeMultipartBody(fields, fileInfo) {
    const boundary = "----WebKitFormBoundary" + Math.random().toString(36).substring(2);
    let body = "";

    for (const [key, value] of Object.entries(fields)) {
        body += `--${boundary}\r\n`;
        body += `Content-Disposition: form-data; name="${key}"\r\n\r\n`;
        body += `${value}\r\n`;
    }

    if (fileInfo) {
        body += `--${boundary}\r\n`;
        body += `Content-Disposition: form-data; name="${fileInfo.name}"; filename="${fileInfo.filename}"\r\n`;
        body += `Content-Type: ${fileInfo.contentType || "application/octet-stream"}\r\n\r\n`;
        body += fileInfo.content;
        body += `\r\n`;
    }

    body += `--${boundary}--\r\n`;

    return {
        boundary,
        body: Buffer.from(body, "utf-8")
    };
}

async function runTests() {
    console.log("==================================================");
    console.log("RUNNING FC-010 DESIGN MANAGEMENT VERIFICATION TESTS");
    console.log("==================================================\n");

    let passed = 0;
    let failed = 0;

    function assert(condition, message) {
        if (condition) {
            console.log(`✅ PASS: ${message}`);
            passed++;
        } else {
            console.error(`❌ FAIL: ${message}`);
            failed++;
        }
    }

    try {
        const adminToken = makeToken(users.admin);
        const pmToken = makeToken(users.pm);
        const designerToken = makeToken(users.assignedDesigner);
        const unassignedToken = makeToken(users.unassignedDesigner);
        const supervisorToken = makeToken(users.supervisor);
        const accountantToken = makeToken(users.accountant);

        // 1. Ensure a valid test project exists
        const createPrjRes = await httpRequest({
            method: "POST",
            path: "/api/projects",
            headers: {
                "Authorization": `Bearer ${adminToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                name: "Test Design Project FC-010",
                clientName: "FC010 Client",
                designerName: "Test DESIGNER",
                startDate: "2026-03-01",
                endDate: "2026-08-30",
                budget: 500000
            })
        });

        const projectId = createPrjRes.body?.data?.id || "PRJ-101";
        console.log(`Using Project ID: ${projectId}`);

        // Assign designer & PM to project team
        await httpRequest({
            method: "PATCH",
            path: `/api/projects/${projectId}/team`,
            headers: {
                "Authorization": `Bearer ${adminToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                assignedTeam: [
                    { userId: users.assignedDesigner.id, role: "DESIGNER" },
                    { userId: users.pm.id, role: "PROJECT_MANAGER" }
                ]
            })
        });

        // TEST 1: Happy Path - Initial Upload (v1.0, PENDING)
        const mp1 = makeMultipartBody(
            { title: "Living Room 3D Render", projectId, category: "THREE_D_RENDER" },
            { name: "file", filename: "render_v1.png", contentType: "image/png", content: "dummy image bytes" }
        );

        const upload1 = await httpRequest({
            method: "POST",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": `multipart/form-data; boundary=${mp1.boundary}`
            },
            body: mp1.body
        });

        console.log("Upload 1 Status:", upload1.status, "Body:", JSON.stringify(upload1.body));

        assert(upload1.status === 201, "Designer uploads initial design (201 Created)");
        assert(upload1.body?.data?.design?.version === "v1.0", "Initial version is v1.0");
        assert(upload1.body?.data?.design?.approvalStatus === "PENDING", "Initial approval status is PENDING");

        const designId1 = upload1.body?.data?.design?.id;

        // TEST 2: PM Approves Design
        const approve1 = await httpRequest({
            method: "POST",
            path: `/api/designs/${designId1}/approve`,
            headers: {
                "Authorization": `Bearer ${pmToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ action: "APPROVE", note: "Render looks great!" })
        });

        assert(approve1.status === 200, "PM approves design (200 OK)");
        assert(approve1.body?.data?.design?.approvalStatus === "APPROVED", "Approval status updated to APPROVED");

        // TEST 3: PM Requests Revision on Another Design
        const mp2 = makeMultipartBody(
            { title: "Kitchen Floor Plan", projectId, category: "FLOOR_PLAN" },
            { name: "file", filename: "kitchen.pdf", contentType: "application/pdf", content: "dummy pdf bytes" }
        );

        const upload2 = await httpRequest({
            method: "POST",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": `multipart/form-data; boundary=${mp2.boundary}`
            },
            body: mp2.body
        });

        const designId2 = upload2.body?.data?.design?.id;

        const reqRevRes = await httpRequest({
            method: "POST",
            path: `/api/designs/${designId2}/approve`,
            headers: {
                "Authorization": `Bearer ${pmToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ action: "REQUEST_REVISION", note: "Please adjust island counter placement." })
        });

        assert(reqRevRes.status === 200, "PM requests revision (200 OK)");
        assert(reqRevRes.body?.data?.design?.approvalStatus === "REVISION_REQUESTED", "Status updated to REVISION_REQUESTED");

        // TEST 4: Designer Uploads Minor Revision (v1.0 -> v1.1)
        const mpRev = makeMultipartBody(
            { title: "Kitchen Floor Plan - Revised", isMajorVersion: "false" },
            { name: "file", filename: "kitchen_v1.1.pdf", contentType: "application/pdf", content: "revised pdf bytes" }
        );

        const uploadRev1 = await httpRequest({
            method: "POST",
            path: `/api/designs/${designId2}/revise`,
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": `multipart/form-data; boundary=${mpRev.boundary}`
            },
            body: mpRev.body
        });

        assert(uploadRev1.status === 201, "Designer uploads minor revision (201 Created)");
        assert(uploadRev1.body?.data?.design?.version === "v1.1", "Minor revision version is v1.1");
        assert(uploadRev1.body?.data?.design?.rootDesignId === designId2, "rootDesignId links back to root design");

        const revId1 = uploadRev1.body?.data?.design?.id;

        // TEST 5: Designer Uploads Major Revision (v1.1 -> v2.0)
        const mpMajor = makeMultipartBody(
            { title: "Kitchen Redesign Complete", isMajorVersion: "true" },
            { name: "file", filename: "kitchen_v2.0.pdf", contentType: "application/pdf", content: "major redesign bytes" }
        );

        const uploadMajor = await httpRequest({
            method: "POST",
            path: `/api/designs/${revId1}/revise`,
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": `multipart/form-data; boundary=${mpMajor.boundary}`
            },
            body: mpMajor.body
        });

        assert(uploadMajor.status === 201, "Designer uploads major revision (201 Created)");
        assert(uploadMajor.body?.data?.design?.version === "v2.0", "Major revision version is v2.0");

        // TEST 6: Validation Rejections
        // 6a: Unsupported file type (.exe)
        const mpExe = makeMultipartBody(
            { title: "Malicious File", projectId, category: "OTHER" },
            { name: "file", filename: "script.exe", contentType: "application/x-msdownload", content: "exe content" }
        );

        const exeRes = await httpRequest({
            method: "POST",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": `multipart/form-data; boundary=${mpExe.boundary}`
            },
            body: mpExe.body
        });

        assert(exeRes.status === 415, "Unsupported file type (.exe) rejected with 415 UNSUPPORTED_FILE_TYPE");
        assert(exeRes.body?.error === "UNSUPPORTED_FILE_TYPE", "Error code is UNSUPPORTED_FILE_TYPE");

        // TEST 7: Permissions Rejections
        // 7a: Unassigned designer attempt to upload to project
        const unassignedUpload = await httpRequest({
            method: "POST",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${unassignedToken}`,
                "Content-Type": `multipart/form-data; boundary=${mp1.boundary}`
            },
            body: mp1.body
        });

        assert(unassignedUpload.status === 403, "Unassigned designer upload rejected with 403 FORBIDDEN");

        // 7b: Designer attempt to approve design
        const designerApprove = await httpRequest({
            method: "POST",
            path: `/api/designs/${designId1}/approve`,
            headers: {
                "Authorization": `Bearer ${designerToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ action: "APPROVE" })
        });

        assert(designerApprove.status === 403, "Designer approval attempt rejected with 403 FORBIDDEN");

        // 7c: Site Supervisor attempt to upload
        const supervisorUpload = await httpRequest({
            method: "POST",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${supervisorToken}`,
                "Content-Type": `multipart/form-data; boundary=${mp1.boundary}`
            },
            body: mp1.body
        });

        assert(supervisorUpload.status === 403, "Site Supervisor upload attempt rejected with 403 FORBIDDEN");

        // 7d: Accountant attempt to access designs
        const accountantGet = await httpRequest({
            method: "GET",
            path: "/api/designs",
            headers: {
                "Authorization": `Bearer ${accountantToken}`
            }
        });

        assert(accountantGet.status === 403, "Accountant access attempt rejected with 403 FORBIDDEN");

        // TEST 8: Download Signed Link
        const downloadRes = await httpRequest({
            method: "GET",
            path: `/api/designs/${designId1}/download`,
            headers: {
                "Authorization": `Bearer ${designerToken}`
            }
        });

        assert(downloadRes.status === 200, "Download URL generated (200 OK)");
        assert(Boolean(downloadRes.body?.data?.downloadUrl), "Download response contains downloadUrl");

        // TEST 9: Non-existent Project ID Query Error
        const nonexistentPrjRes = await httpRequest({
            method: "GET",
            path: "/api/designs?projectId=PRJ-NONEXISTENT-9999",
            headers: {
                "Authorization": `Bearer ${adminToken}`
            }
        });

        assert(nonexistentPrjRes.status === 404, "Non-existent project query returns 404 PROJECT_NOT_FOUND");
        assert(nonexistentPrjRes.body?.error === "PROJECT_NOT_FOUND", "Error code is PROJECT_NOT_FOUND");

    } catch (err) {
        console.error("Test execution failed:", err);
    }

    console.log("\n==================================================");
    console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
    console.log("==================================================\n");

    if (failed > 0) {
        process.exit(1);
    }
}

runTests();
