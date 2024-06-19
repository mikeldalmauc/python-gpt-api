import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import { initializeUser, updateUser, readUser, deleteUser } from '../../../src/repository/mongo/userRepo.mjs'; // adjust the path as necessary

// Define the user schema to avoid model overwrite issues
const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  conversationHistory: Array,
});
const User = mongoose.model('User', userSchema);

beforeAll(async () => {
  const dbUri = 'mongodb://localhost:27017/testDatabase'; // Use a test database
  await mongoose.connect(dbUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useCreateIndex: true,
    useFindAndModify: false,
  });
});

afterAll(async () => {
  await mongoose.connection.db.dropDatabase();
  await mongoose.connection.close();
});

describe('UserRepo Tests', () => {
  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const updatedName = 'Test User Updated';

  beforeEach(async () => {
    await User.deleteMany({});
  });

  test('should create a user', async () => {
    await initializeUser('Test User', testEmail, testPassword);
    const user = await User.findOne({ email: testEmail });
    expect(user).not.toBeNull();
    const passwordMatch = await bcrypt.compare(testPassword, user.password);
    expect(passwordMatch).toBe(true);
  });

  test('should read a user', async () => {
    await initializeUser('Test User', testEmail, testPassword);
    const user = await readUser(testEmail);
    expect(user).not.toBeNull();
    expect(user.email).toBe(testEmail);
  });

  test('should update a user', async () => {
    await initializeUser('Test User', testEmail, testPassword);
    await updateUser(testEmail, { name: updatedName });
    const user = await User.findOne({ email: testEmail });
    expect(user.name).toBe(updatedName);
  });

  test('should delete a user', async () => {
    await initializeUser('Test User', testEmail, testPassword);
    await deleteUser(testEmail);
    const user = await User.findOne({ email: testEmail });
    expect(user).toBeNull();
  });
});
