import mongoose from 'mongoose';
import bcrypt from 'bcrypt';

// Crear el modelo de usuario
const User = mongoose.model('User', userSchema);

// Función para inicializar un usuario
async function initializeUser(name, email, password) {
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = new User({
            name: name,
            email: email,
            password: hashedPassword,
            conversationHistory: []
        });
        await newUser.save();
        console.log('Usuario creado exitosamente');
    } catch (error) {
        console.error('Error al crear el usuario:', error);
    }
}

// Función para eliminar un usuario
async function deleteUser(email) {
    try {
        await User.findOneAndDelete({ email: email });
        console.log('Usuario eliminado exitosamente');
    } catch (error) {
        console.error('Error al eliminar el usuario:', error);
    }
}

// Función para leer los datos de un usuario
async function readUser(email) {
    try {
        const user = await User.findOne({ email: email });
        if (user) {
            console.log('Datos del usuario:', user);
        } else {
            console.log('Usuario no encontrado');
        }
    } catch (error) {
        console.error('Error al leer el usuario:', error);
    }
}

// Función para actualizar los datos de un usuario
async function updateUser(email, updatedData) {
    try {
        const user = await User.findOneAndUpdate({ email: email }, updatedData, { new: true });
        if (user) {
            console.log('Usuario actualizado exitosamente:', user);
        } else {
            console.log('Usuario no encontrado');
        }
    } catch (error) {
        console.error('Error al actualizar el usuario:', error);
    }
}

// Ejemplo de uso
(async () => {
    await initializeUser('John Doe', 'john@example.com', 'password123');
    await readUser('john@example.com');
    await updateUser('john@example.com', { name: 'Johnathan Doe' });
    await deleteUser('john@example.com');
    mongoose.connection.close();
})();