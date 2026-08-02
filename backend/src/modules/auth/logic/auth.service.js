const bcrypt = require("bcrypt");
const crypto = require("crypto");

const {
    createUser,
    findUserByEmail,
    updateUser,
    findUserByRefreshToken,
    findUserByResetToken
} = require("../data/auth.repository");


const {
    generateAccessToken,
    generateRefreshToken
} = require("../../../utils/token");



// ================= REGISTER =================

const registerUser = async (userData) => {

    const existingUser = await findUserByEmail(
        userData.email
    );


    if (existingUser) {
        throw new Error("Email already registered");
    }


    const hashedPassword = await bcrypt.hash(
        userData.password,
        10
    );


    const createData = {
        fullName: userData.fullName,
        email: userData.email,
        password: hashedPassword,
        role: userData.role
    };

    if (userData.phone) {
        createData.phone = userData.phone;
    }

    let user;
    try {
        user = await createUser(createData);
    } catch (dbError) {
        // Fallback if phone column isn't pushed to PostgreSQL table yet
        if (createData.phone) {
            delete createData.phone;
            user = await createUser(createData);
        } else {
            throw dbError;
        }
    }

    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    const updatedUser = await updateUser(
        user.id,
        {
            refreshToken
        }
    );

    return {
        accessToken,
        refreshToken,
        user: updatedUser
    };
};



// ================= LOGIN =================

const loginUser = async (userData) => {

    const user = await findUserByEmail(
        userData.email
    );


    if (!user) {
        throw new Error("Invalid email or password");
    }


    const passwordMatch = await bcrypt.compare(
        userData.password,
        user.password
    );


    if (!passwordMatch) {
        throw new Error("Invalid email or password");
    }


    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };


    const accessToken = generateAccessToken(payload);

    const refreshToken = generateRefreshToken(payload);


const updatedUser = await updateUser(
    user.id,
    {
        refreshToken
    }
);


return {
    accessToken,
    refreshToken,
    user: updatedUser
};
    
};



// ================= LOGOUT =================

const logoutUser = async (userId) => {


    await updateUser(
        userId,
        {
            refreshToken: null
        }
    );


    return {
        message: "Logout successful"
    };

};



// ================= REFRESH TOKEN =================

const refreshTokenUser = async (token) => {


    const user = await findUserByRefreshToken(token);


    if (!user) {
        throw new Error("Invalid refresh token");
    }


    const payload = {

        id: user.id,

        email: user.email,

        role: user.role

    };


    const newAccessToken =
        generateAccessToken(payload);



    return {
        accessToken: newAccessToken
    };

};



// ================= FORGOT PASSWORD =================

const forgotPasswordUser = async (email) => {


    const user = await findUserByEmail(email);


    if (!user) {
        throw new Error("User not found");
    }


    const resetToken =
        crypto.randomBytes(32).toString("hex");


    await updateUser(

        user.id,

        {

            resetToken,

            resetTokenExpiry:
                new Date(Date.now() + 15 * 60 * 1000)

        }

    );


    return {

        message: "Password reset token generated",

        resetToken

    };

};



// ================= RESET PASSWORD =================

const resetPasswordUser = async (data) => {


    const user =
        await findUserByResetToken(
            data.token
        );


    if (!user) {
        throw new Error("Invalid reset token");
    }


    if (
        user.resetTokenExpiry < new Date()
    ) {

        throw new Error("Reset token expired");

    }


    const hashedPassword =
        await bcrypt.hash(
            data.password,
            10
        );


    await updateUser(

        user.id,

        {

            password: hashedPassword,

            resetToken: null,

            resetTokenExpiry: null

        }

    );


    return {
        message: "Password reset successful"
    };

};



module.exports = {

    registerUser,

    loginUser,

    logoutUser,

    refreshTokenUser,

    forgotPasswordUser,

    resetPasswordUser

};