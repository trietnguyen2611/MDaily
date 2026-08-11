/**
 * Auth Service for MDaily
 * Handles registration, login, logout, and session state.
 */

import { db } from './db.js';

export const auth = {
  login(email, password) {
    const users = db.getUsers();
    const found = users.find((u) => u.email.toLowerCase() === email.toLowerCase() && u.password === password);
    if (found) {
      db.setCurrentUserEmail(found.email);
      return { success: true, user: found };
    }
    return { success: false, message: 'Email hoặc mật khẩu không chính xác' };
  },

  register(name, email, password) {
    const users = db.getUsers();
    const exists = users.some((u) => u.email.toLowerCase() === email.toLowerCase());
    if (exists) {
      return { success: false, message: 'Email đã tồn tại trên hệ thống' };
    }
    const newUser = { name, email, password };
    db.saveUser(newUser);
    db.setCurrentUserEmail(email);
    return { success: true, user: newUser };
  },

  logout() {
    db.setCurrentUserEmail('');
  },

  getCurrentUser() {
    return db.getCurrentUser();
  },

  isLoggedIn() {
    return !!db.getCurrentUserEmail();
  }
};
