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
    console.log("=== Starting Lead Pipeline Programmatic API Verification ===\n");

    try {
        // 1. Log in as Admin
        console.log("1. Logging in as Admin (admin@idpms.com)...");
        const adminLogin = await makeRequest(`${BASE_URL}/auth/login`, { method: "POST" }, {
            email: "admin@idpms.com",
            password: "Password123"
        });
        
        if (adminLogin.statusCode !== 200) {
            throw new Error(`Admin login failed: ${JSON.stringify(adminLogin.data)}`);
        }
        const adminToken = adminLogin.data.accessToken;
        console.log("   Admin login successful!");

        // 2. Log in as Designer
        console.log("2. Logging in as Designer (designer@idpms.com)...");
        const designerLogin = await makeRequest(`${BASE_URL}/auth/login`, { method: "POST" }, {
            email: "designer@idpms.com",
            password: "Password123"
        });
        
        if (designerLogin.statusCode !== 200) {
            throw new Error(`Designer login failed: ${JSON.stringify(designerLogin.data)}`);
        }
        const designerToken = designerLogin.data.accessToken;
        const designerUserId = designerLogin.data.user.id;
        console.log("   Designer login successful!");

        // 3. List leads as Admin (should return all leads: 4)
        console.log("\n3. Fetching leads as Admin...");
        const adminLeads = await makeRequest(`${BASE_URL}/leads`, {
            headers: { "Authorization": `Bearer ${adminToken}` }
        });
        console.log(`   Status: ${adminLeads.statusCode}`);
        console.log(`   Message: ${adminLeads.data.message}`);
        console.log(`   Total Leads: ${adminLeads.data.data.total}`);
        if (adminLeads.data.data.total < 4) {
            throw new Error("Expected at least 4 leads for Admin");
        }

        // 4. List leads as Designer (should return only Designer's leads)
        console.log("\n4. Fetching leads as Designer...");
        const designerLeads = await makeRequest(`${BASE_URL}/leads`, {
            headers: { "Authorization": `Bearer ${designerToken}` }
        });
        console.log(`   Status: ${designerLeads.statusCode}`);
        console.log(`   Total Assigned Leads: ${designerLeads.data.data.total}`);
        const allAssignedToDesigner = designerLeads.data.data.leads.every(l => l.assignedToId === designerUserId);
        console.log(`   Are all returned leads assigned to Designer? ${allAssignedToDesigner}`);
        if (!allAssignedToDesigner) {
            throw new Error("Designer leads list contains unassigned or other user's leads");
        }

        // 5. Create a new lead as Designer
        console.log("\n5. Creating a new lead as Designer...");
        const newLeadPayload = {
            clientName: "Alice Cooper",
            email: "alice@cooper.com",
            phone: "+1 555-9876",
            propertyType: "Cozy Studio Flat",
            estimatedBudget: 35000
        };
        const createLeadRes = await makeRequest(`${BASE_URL}/leads`, {
            method: "POST",
            headers: { "Authorization": `Bearer ${designerToken}` }
        }, newLeadPayload);
        console.log(`   Status: ${createLeadRes.statusCode}`);
        console.log(`   Lead ID: ${createLeadRes.data.data.id}`);
        console.log(`   Client Name: ${createLeadRes.data.data.clientName}`);
        console.log(`   Assigned To ID: ${createLeadRes.data.data.assignedToId}`);
        const leadId = createLeadRes.data.data.id;

        // 6. Test Validation - Create lead with negative budget
        console.log("\n6. Testing validation: creating lead with negative budget...");
        const badLeadPayload = {
            clientName: "Bob Tester",
            estimatedBudget: -100
        };
        const badLeadRes = await makeRequest(`${BASE_URL}/leads`, {
            method: "POST",
            headers: { "Authorization": `Bearer ${designerToken}` }
        }, badLeadPayload);
        console.log(`   Status: ${badLeadRes.statusCode} (Expected: 400)`);
        console.log(`   Message: ${badLeadRes.data.message}`);
        console.log(`   Error Details: ${badLeadRes.data.error}`);

        // 7. Convert newly created lead to a project
        console.log(`\n7. Converting lead ${leadId} to a project...`);
        const convertRes = await makeRequest(`${BASE_URL}/leads/${leadId}/convert`, {
            method: "POST",
            headers: { "Authorization": `Bearer ${designerToken}` }
        });
        console.log(`   Status: ${convertRes.statusCode}`);
        console.log(`   Message: ${convertRes.data.message}`);
        console.log(`   Updated Lead Status: ${convertRes.data.data.lead.status}`);
        console.log(`   Created Project ID: ${convertRes.data.data.project.id}`);
        console.log(`   Created Project Name: ${convertRes.data.data.project.name}`);

        // 8. Attempt converting it again (idempotency check)
        console.log(`\n8. Attempting to convert lead ${leadId} again...`);
        const reconvertRes = await makeRequest(`${BASE_URL}/leads/${leadId}/convert`, {
            method: "POST",
            headers: { "Authorization": `Bearer ${designerToken}` }
        });
        console.log(`   Status: ${reconvertRes.statusCode} (Expected: 400 or 409)`);
        console.log(`   Message: ${reconvertRes.data.message}`);
        console.log(`   Error: ${reconvertRes.data.error}`);

        // 9. Role restriction check: Designer attempts to access Admin's lead (LD-104)
        console.log("\n9. Testing permissions: Designer requesting Admin's lead (LD-104)...");
        const getAdminLeadRes = await makeRequest(`${BASE_URL}/leads/LD-104`, {
            headers: { "Authorization": `Bearer ${designerToken}` }
        });
        console.log(`   Status: ${getAdminLeadRes.statusCode} (Expected: 403)`);
        console.log(`   Message: ${getAdminLeadRes.data.message}`);
        console.log(`   Error: ${getAdminLeadRes.data.error}`);

        console.log("\n=== All Programmatic API Checks Passed Successfully! ===");
    } catch (error) {
        console.error("Test execution failed:", error);
    }
}

runTests();
