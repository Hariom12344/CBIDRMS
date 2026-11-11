const nodemailer = require("nodemailer");

let cachedEtherealTransporter = null;

/**
 * Get active transporter. Fallback to auto-created Ethereal test account if SMTP is omitted.
 */
const getTransporter = async () => {
    const host = process.env.SMTP_HOST || process.env.EMAIL_HOST || "smtp.gmail.com";
    const user = process.env.SMTP_USER || process.env.EMAIL_USER || "idpmsdesign@gmail.com";
    const pass = process.env.SMTP_PASS || process.env.EMAIL_PASSWORD;

    if (user && pass && pass.trim().length > 0) {
        const isGmail = (host && host.includes("gmail")) || (user && user.includes("gmail.com"));
        const transportConfig = isGmail
            ? {
                service: "gmail",
                auth: { user, pass }
            }
            : {
                host: host || "smtp.gmail.com",
                port: parseInt(process.env.SMTP_PORT || process.env.EMAIL_PORT || "587", 10),
                secure: process.env.SMTP_SECURE === "true" || parseInt(process.env.SMTP_PORT || "587", 10) === 465,
                auth: { user, pass }
            };

        return {
            transporter: nodemailer.createTransport(transportConfig),
            isEthereal: false
        };
    }

    // Auto-create Ethereal test account if SMTP credentials are missing
    if (!cachedEtherealTransporter) {
        try {
            console.warn(`\n[EMAIL SERVICE WARNING] SMTP_PASS is missing in backend/.env!`);
            console.warn(`[EMAIL SERVICE WARNING] Real emails from idpmsdesign@gmail.com CANNOT be delivered to recipient inboxes without a Google App Password.`);
            console.warn(`[EMAIL SERVICE WARNING] Falling back to development test inbox mode...\n`);
            
            const testAccount = await nodemailer.createTestAccount();
            cachedEtherealTransporter = nodemailer.createTransport({
                host: testAccount.smtp.host,
                port: testAccount.smtp.port,
                secure: testAccount.smtp.secure,
                auth: {
                    user: testAccount.user,
                    pass: testAccount.pass
                }
            });
            console.log(`[EMAIL SERVICE] Initialized Ethereal Test Email Account: ${testAccount.user}`);
        } catch (err) {
            console.warn(`[EMAIL SERVICE] Could not create Ethereal test account: ${err.message}`);
            return { transporter: null, isEthereal: false };
        }
    }

    return { transporter: cachedEtherealTransporter, isEthereal: true };
};

/**
 * Send Password Reset Email to User
 * @param {string} toEmail - Recipient email address
 * @param {string} resetToken - Raw reset token
 */
const sendPasswordResetEmail = async (toEmail, resetToken) => {
    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";
    const resetLink = `${frontendUrl}/reset-password?token=${resetToken}`;
    const fromAddress = process.env.SMTP_FROM || process.env.EMAIL_FROM || '"CIDRMS Team" <idpmsdesign@gmail.com>';

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #1e293b; margin-top: 0;">Reset Your CIDRMS Password</h2>
            <p>Hello,</p>
            <p>We received a request to reset your CIDRMS password.</p>

            <div style="background-color: #f1f5f9; padding: 16px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #cbd5e1;">
                <span style="font-size: 13px; color: #64748b; display: block; margin-bottom: 6px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">Your Password Reset Token:</span>
                <strong style="font-size: 18px; font-family: monospace; color: #2563eb; word-break: break-all; user-select: all;">${resetToken}</strong>
            </div>

            <p style="text-align: center; margin: 25px 0;">
                <a href="${resetLink}" style="background-color: #2563eb; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Reset Password Direct Link</a>
            </p>

            <p style="font-size: 13px; color: #6b7280;">This link and token will expire in 30 minutes.</p>
            <p style="font-size: 13px; color: #6b7280;">If you did not request this password reset, you can safely ignore this email.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;" />
            <p style="font-size: 12px; color: #9ca3af;">Regards,<br/><strong>CIDRMS Team</strong></p>
        </div>
    `;

    const textContent = `Hello,\n\nWe received a request to reset your CIDRMS password.\n\nYour Password Reset Token:\n${resetToken}\n\nReset Link:\n${resetLink}\n\nThis token and link will expire in 30 minutes.\n\nIf you did not request this password reset, you can safely ignore this email.\n\nRegards,\nCIDRMS Team`;

    const { transporter, isEthereal } = await getTransporter();

    if (!transporter) {
        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE] (Console Mode - No Transporter Available)`);
        console.log(`To: ${toEmail}`);
        console.log(`==================================================\n`);
        return { success: true, mode: "console", resetLink };
    }

    try {
        const info = await transporter.sendMail({
            from: fromAddress,
            to: toEmail,
            subject: "Reset Your CIDRMS Password",
            text: textContent,
            html: htmlContent
        });

        console.log(`[EMAIL SERVICE] Email sent successfully to ${toEmail}`);

        if (isEthereal) {
            const previewUrl = nodemailer.getTestMessageUrl(info);
            if (previewUrl) {
                console.log(`[EMAIL SERVICE] Preview link (Ethereal test mode): ${previewUrl}`);
            }
        }

        return {
            success: true,
            mode: isEthereal ? "ethereal" : "smtp",
            messageId: info.messageId
        };
    } catch (err) {
        console.error(`[EMAIL SERVICE ERROR] Failed to send email to ${toEmail}:`, err.message);
        return { success: false, error: err.message, mode: "fallback" };
    }
};

/**
 * Send Welcome / Set Password Email to Newly Created User
 * @param {string} toEmail - Recipient email address
 * @param {string} resetToken - Raw setup token
 */
const sendUserWelcomeEmail = async (toEmail, resetToken) => {
    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";
    const setupLink = `${frontendUrl}/reset-password?token=${resetToken}`;
    const fromAddress = process.env.EMAIL_FROM || '"CDBIRMS Support" <noreply@cdbirms.com>';

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #2c3e50;">Welcome to CDBIRMS</h2>
            <p>Hello,</p>
            <p>An account has been created for you on CDBIRMS. Please set your password using the token or link below:</p>
            
            <div style="background-color: #f4f6f8; padding: 15px; border-radius: 6px; text-align: center; margin: 20px 0;">
                <span style="font-size: 14px; color: #7f8c8d; display: block; margin-bottom: 5px;">Your Activation Token:</span>
                <strong style="font-size: 20px; font-family: monospace; letter-spacing: 1px; color: #27ae60;">${resetToken}</strong>
            </div>

            <p style="text-align: center; margin: 25px 0;">
                <a href="${setupLink}" style="background-color: #27ae60; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">Set Your Password</a>
            </p>

            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;" />
            <p style="font-size: 11px; color: #bdc3c7; text-align: center;">CDBIRMS System Notification</p>
        </div>
    `;

    const { transporter, isEthereal } = await getTransporter();

    if (!transporter) {
        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE] (Console Mode - Setup Email)`);
        console.log(`To: ${toEmail}`);
        console.log(`Setup Token: ${resetToken}`);
        console.log(`Setup Link:  ${setupLink}`);
        console.log(`==================================================\n`);
        return { success: true, mode: "console", resetToken, setupLink };
    }

    try {
        const info = await transporter.sendMail({
            from: fromAddress,
            to: toEmail,
            subject: "Welcome to CDBIRMS - Set Your Password",
            text: `Welcome to CDBIRMS!\n\nToken: ${resetToken}\nLink: ${setupLink}`,
            html: htmlContent
        });

        const previewUrl = nodemailer.getTestMessageUrl(info);

        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE] Welcome email dispatched to ${toEmail}`);
        console.log(`Setup Token: ${resetToken}`);
        console.log(`Setup Link:  ${setupLink}`);
        if (isEthereal && previewUrl) {
            console.log(`\n📬 VIEW EMAIL IN BROWSER (Ethereal Test Inbox):`);
            console.log(`🔗 ${previewUrl}`);
        }
        console.log(`==================================================\n`);

        return {
            success: true,
            mode: isEthereal ? "ethereal" : "smtp",
            messageId: info.messageId,
            previewUrl
        };
    } catch (err) {
        console.error(`[EMAIL SERVICE ERROR] Failed to send welcome email to ${toEmail}:`, err.message);
        console.log(`[EMAIL SERVICE FALLBACK] Setup Token: ${resetToken} | Link: ${setupLink}`);
        return { success: false, error: err.message, mode: "fallback", resetToken, setupLink };
    }
};

/**
 * Send Design Notification Email
 * @param {Object} options
 * @param {string} options.toEmail - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.title - Design title
 * @param {string} options.projectName - Project name
 * @param {string} options.action - UPLOAD, REVISION, APPROVE, REQUEST_REVISION
 * @param {string} options.version - Design version e.g. v1.0
 * @param {string} [options.note] - Optional revision note
 */
const sendDesignNotificationEmail = async ({ toEmail, subject, title, projectName, action, version, note }) => {
    if (!toEmail) return { success: false, message: "No recipient email provided" };

    const fromAddress = process.env.SMTP_FROM || process.env.EMAIL_FROM || '"CIDRMS Design Notifications" <idpmsdesign@gmail.com>';

    let actionLabel = "uploaded a new design";
    if (action === "REVISION") actionLabel = "uploaded a new design revision";
    if (action === "APPROVE") actionLabel = "approved the design";
    if (action === "REQUEST_REVISION") actionLabel = "requested revision for the design";

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #1e293b; margin-top: 0;">CIDRMS Design Update</h2>
            <p>Hello,</p>
            <p>A design update has occurred in <strong>${projectName}</strong>:</p>
            <div style="background-color: #f8fafc; padding: 16px; border-radius: 8px; margin: 20px 0; border: 1px solid #e2e8f0;">
                <p style="margin: 4px 0;"><strong>Design Title:</strong> ${title}</p>
                <p style="margin: 4px 0;"><strong>Version:</strong> ${version}</p>
                <p style="margin: 4px 0;"><strong>Action:</strong> ${actionLabel}</p>
                ${note ? `<p style="margin: 4px 0; color: #475569;"><strong>Notes / Feedback:</strong> ${note}</p>` : ""}
            </div>
            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;" />
            <p style="font-size: 12px; color: #9ca3af;">Regards,<br/><strong>CIDRMS Design Module</strong></p>
        </div>
    `;

    const { transporter, isEthereal } = await getTransporter();

    if (!transporter) {
        console.log(`[DESIGN NOTIFICATION] To: ${toEmail} | Subject: ${subject} | Action: ${action}`);
        return { success: true, mode: "console" };
    }

    try {
        const info = await transporter.sendMail({
            from: fromAddress,
            to: toEmail,
            subject,
            html: htmlContent
        });
        console.log(`[DESIGN NOTIFICATION] Dispatched to ${toEmail}`);
        return { success: true, mode: isEthereal ? "ethereal" : "smtp", messageId: info.messageId };
    } catch (err) {
        console.error(`[DESIGN NOTIFICATION ERROR] Failed to send email to ${toEmail}:`, err.message);
        return { success: false, error: err.message };
    }
};

module.exports = {
    sendPasswordResetEmail,
    sendUserWelcomeEmail,
    sendDesignNotificationEmail
};
