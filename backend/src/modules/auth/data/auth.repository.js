const prisma = require("../../../config/db");


// Create new user
const createUser = async (userData) => {

    return await prisma.user.create({
        data: userData
    });

};


// Find user by email
const findUserByEmail = async (email) => {

    return await prisma.user.findUnique({
        where: {
            email
        }
    });

};


// Update user data
const updateUser = async (id, data) => {

    return await prisma.user.update({

        where: {
            id
        },

        data

    });

};


// Find user by refresh token
const findUserByRefreshToken = async (token) => {

    return await prisma.user.findFirst({

        where: {
            refreshToken: token
        }

    });

};


// Find user by reset token
const findUserByResetToken = async (token) => {

    return await prisma.user.findFirst({

        where: {
            resetToken: token
        }

    });

};


module.exports = {

    createUser,
    findUserByEmail,
    updateUser,
    findUserByRefreshToken,
    findUserByResetToken

};