import { test, expect } from '@playwright/test';

test.describe('Smoke Testing & Basic UI/UX', () => {
  test('App should load and display login screen', async ({ page }) => {
    // Navigate to the app
    await page.goto('/');

    // Check if the page title is correct (adjust if needed)
    await expect(page).toHaveTitle(/UnityHub|Vite \+ React/i);

    // Check if the main login container is visible
    // This acts as a basic smoke test to ensure the app doesn't crash on load
    const loginContainer = page.locator('text=Login');
    await expect(loginContainer.first()).toBeVisible();
  });

  test('UI/UX: Check basic accessibility on login page', async ({ page }) => {
    await page.goto('/');
    
    // Check if buttons have accessible names
    const buttons = page.locator('button');
    const count = await buttons.count();
    for (let i = 0; i < count; i++) {
      const name = await buttons.nth(i).textContent();
      expect(name?.trim().length).toBeGreaterThan(0);
    }
  });
});
