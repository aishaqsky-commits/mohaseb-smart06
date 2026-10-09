/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/tests"],
  testMatch: ["**/*.test.ts"],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        tsconfig: {
          target: "ES2022",
          module: "commonjs",
          strict: true,
          esModuleInterop: true,
          resolveJsonModule: true,
          types: ["jest", "node"],
          // تخفيف القيود الصارمة الخاصة بالبناء فقط لتسهيل اختبار ملفات الاختبار
          noUncheckedIndexedAccess: false,
          exactOptionalPropertyTypes: false,
        },
      },
    ],
  },
  collectCoverageFrom: ["src/**/*.ts", "!src/**/*.d.ts"],
};
