const nodemailer = require("nodemailer");

let cachedEtherealTransporter = null;

/**
 * Get active SMTP transporter. Supports EMAIL_* and SMTP_* env variables.
 * Falls back to Ethereal Test Account if credentials are not configured.
 */
const getTransporter = async () => {
    const host = process.env.EMAIL_HOST || process.env.SMTP_HOST || "smtp.gmail.com";
    const user = process.env.EMAIL_USER || process.env.SMTP_USER;
    const pass = process.env.EMAIL_PASSWORD || process.env.SMTP_PASS;

    if (user && pass && pass.trim().length > 0) {
        const isGmail = (host && host.includes("gmail")) || (user && user.includes("gmail.com"));
        const transportConfig = isGmail
            ? {
                service: "gmail",
                auth: { user, pass }
            }
            : {
                host,
                port: parseInt(process.env.EMAIL_PORT || process.env.SMTP_PORT || "587", 10),
                secure: process.env.SMTP_SECURE === "true" || parseInt(process.env.EMAIL_PORT || process.env.SMTP_PORT || "587", 10) === 465,
                auth: { user, pass }
            };

        return {
            transporter: nodemailer.createTransport(transportConfig),
            isEthereal: false
        };
    }

    console.warn(`\n[EMAIL SERVICE WARNING] SMTP_PASS / EMAIL_PASSWORD is missing in backend/.env!`);
    console.warn(`[EMAIL SERVICE WARNING] Real emails CANNOT be delivered to recipient inboxes without a valid Google App Password.`);
    console.warn(`[EMAIL SERVICE WARNING] Using development console fallback mode...\n`);

    // Fallback: auto-generate Ethereal test inbox for development
    if (!cachedEtherealTransporter) {
        try {
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
            console.log(`[EMAIL SERVICE] Initialized Ethereal Test Account: ${testAccount.user}`);
        } catch (err) {
            console.warn(`[EMAIL SERVICE WARNING] Ethereal account creation failed: ${err.message}`);
            return { transporter: null, isEthereal: false };
        }
    }

    return { transporter: cachedEtherealTransporter, isEthereal: true };
};

/**
 * Send Password Reset Email to User
 * @param {string} toEmail - Recipient email address
 * @param {string} rawResetToken - Unhashed reset token (sent only via email)
 */
const sendPasswordResetEmail = async (toEmail, rawResetToken) => {
    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";
    const expiryMinutes = process.env.RESET_TOKEN_EXPIRY_MINUTES || "30";
    const resetLink = `${frontendUrl}/reset-password?token=${rawResetToken}`;
    const fromAddress = process.env.EMAIL_FROM || process.env.SMTP_FROM || '"CIDRMS Team" <noreply@cidrms.com>';

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #ffffff;">
            <h2 style="color: #1a365d; margin-bottom: 16px;">Reset Your CIDRMS Password</h2>
            <p style="color: #4a5568; font-size: 15px; line-height: 1.5;">Hello,</p>
            <p style="color: #4a5568; font-size: 15px; line-height: 1.5;">We received a request to reset your CIDRMS password.</p>
            <p style="color: #4a5568; font-size: 15px; line-height: 1.5;">Click the button below or copy the reset token to create a new password:</p>
            
            <div style="background-color: #f1f5f9; padding: 16px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #cbd5e1;">
                <span style="font-size: 13px; color: #64748b; display: block; margin-bottom: 6px; font-weight: 600; text-transform: uppercase;">Your Reset Token:</span>
                <strong style="font-size: 16px; font-family: monospace; color: #2563eb; word-break: break-all;">${rawResetToken}</strong>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${resetLink}" style="background-color: #2b6cb0; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">Reset Password</a>
            </div>

            <p style="color: #718096; font-size: 13px; line-height: 1.4;">This link will expire in ${expiryMinutes} minutes.</p>
            <p style="color: #718096; font-size: 13px; line-height: 1.4;">If you did not request this password reset, you can safely ignore this email.</p>
            
            <hr style="border: none; border-top: 1px solid #e2e8f0; margin-top: 30px; margin-bottom: 20px;" />
            <p style="color: #a0aec0; font-size: 12px; text-align: center; margin: 0;">Regards,<br><strong>CIDRMS Team</strong></p>
        </div>
    `;

    const textContent = `Hello,\n\nWe received a request to reset your CIDRMS password.\n\nReset Token: ${rawResetToken}\nReset Link: ${resetLink}\n\nThis link will expire in ${expiryMinutes} minutes.\n\nIf you did not request this password reset, you can safely ignore this email.\n\nRegards,\nCIDRMS Team`;

    const { transporter, isEthereal } = await getTransporter();

    if (!transporter) {
        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE] (Console Fallback Mode)`);
        console.log(`To: ${toEmail}`);
        console.log(`🔑 Reset Token: ${rawResetToken}`);
        console.log(`🔗 Reset Link:  ${resetLink}`);
        console.log(`==================================================\n`);
        return { success: true, mode: "console", resetLink, resetToken: rawResetToken };
    }

    try {
        const info = await transporter.sendMail({
            from: fromAddress,
            to: toEmail,
            subject: "Reset Your CIDRMS Password",
            text: textContent,
            html: htmlContent
        });

        const previewUrl = nodemailer.getTestMessageUrl(info);

        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE] Password reset requested for: ${toEmail}`);
        console.log(`🔑 Reset Token: ${rawResetToken}`);
        console.log(`🔗 Reset Link:  ${resetLink}`);

        if (isEthereal) {
            console.log(`\n⚠️ NOTE: EMAIL WAS NOT DELIVERED TO USER'S REAL GMAIL INBOX.`);
            console.log(`To send real emails to Gmail, add a Google App Password to SMTP_PASS in backend/.env`);
            if (previewUrl) {
                console.log(`\n📬 VIEW MOCK EMAIL IN BROWSER (Ethereal Inbox):`);
                console.log(`🔗 ${previewUrl}`);
            }
        } else {
            console.log(`✅ Real email dispatched successfully via SMTP to ${toEmail}`);
        }
        console.log(`==================================================\n`);

        return {
            success: true,
            mode: isEthereal ? "ethereal" : "smtp",
            messageId: info.messageId,
            previewUrl,
            resetLink,
            resetToken: rawResetToken
        };
    } catch (err) {
        console.error(`[EMAIL SERVICE ERROR] Failed to dispatch email to ${toEmail}:`, err.message);
        console.log(`\n==================================================`);
        console.log(`[EMAIL SERVICE FALLBACK] (Console Mode)`);
        console.log(`To: ${toEmail}`);
        console.log(`🔑 Reset Token: ${rawResetToken}`);
        console.log(`🔗 Reset Link:  ${resetLink}`);
        console.log(`==================================================\n`);
        return { success: false, error: err.message, mode: "fallback", resetLink, resetToken: rawResetToken };
    }
};

/**
 * Send Welcome / Registration Confirmation Email to New User
 * @param {string} toEmail - Recipient email address
 * @param {string} fullName - User full name
 * @param {string} role - User role
 */
const sendRegistrationWelcomeEmail = async (toEmail, fullName, role) => {
    const fromAddress = process.env.EMAIL_FROM || process.env.SMTP_FROM || '"CIDRMS Team" <noreply@cidrms.com>';

    const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 25px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #ffffff;">
            <h2 style="color: #1a365d; margin-bottom: 16px;">Welcome to CIDRMS!</h2>
            <p style="color: #4a5568; font-size: 15px; line-height: 1.5;">Hello <strong>${fullName}</strong>,</p>
            <p style="color: #4a5568; font-size: 15px; line-height: 1.5;">Thank you for registering with CIDRMS. Your account has been successfully created.</p>
            
            <div style="background-color: #f1f5f9; padding: 16px; border-radius: 8px; margin: 20px 0; border: 1px solid #cbd5e1;">
                <p style="margin: 4px 0; color: #334155; font-size: 14px;"><strong>Registered Email:</strong> ${toEmail}</p>
                <p style="margin: 4px 0; color: #334155; font-size: 14px;"><strong>Account Role:</strong> ${role}</p>
            </div>

            <p style="color: #718096; font-size: 13px; line-height: 1.4;">You can now log in to access your CIDRMS workspace.</p>
            
            <hr style="border: none; border-top: 1px solid #e2e8f0; margin-top: 30px; margin-bottom: 20px;" />
            <p style="color: #a0aec0; font-size: 12px; text-align: center; margin: 0;">Regards,<br><strong>CIDRMS Team</strong></p>
        </div>
    `;

    const textContent = `Hello ${fullName},\n\nThank you for registering with CIDRMS. Your account has been successfully created.\n\nRegistered Email: ${toEmail}\nAccount Role: ${role}\n\nRegards,\nCIDRMS Team`;

    const { transporter, isEthereal } = await getTransporter();

    if (!transporter) {
        console.log(`[EMAIL SERVICE] (Console Mode - Welcome Email) Registration confirmed for ${toEmail}`);
        return { success: true, mode: "console" };
    }

    try {
        const info = await transporter.sendMail({
            from: fromAddress,
            to: toEmail,
            subject: "Welcome to CIDRMS - Registration Successful",
            text: textContent,
            html: htmlContent
        });

        const previewUrl = nodemailer.getTestMessageUrl(info);
        console.log(`[EMAIL SERVICE] Registration welcome email dispatched to ${toEmail}`);
        if (isEthereal && previewUrl) {
            console.log(`[EMAIL SERVICE] Ethereal Preview URL: ${previewUrl}`);
        }

        return { success: true, mode: isEthereal ? "ethereal" : "smtp", messageId: info.messageId, previewUrl };
    } catch (err) {
        console.error(`[EMAIL SERVICE ERROR] Failed to send welcome email to ${toEmail}:`, err.message);
        return { success: false, error: err.message };
    }
};

module.exports = {
    sendPasswordResetEmail,
    sendRegistrationWelcomeEmail
};
