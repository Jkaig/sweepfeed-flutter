"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logError = exports.trackFunctionExecution = exports.healthCheck = exports.dailyHealthReport = exports.monitorFunctionPerformance = exports.detectUsageSpikes = exports.monitorFirestoreQuota = void 0;
// Export all monitoring functions
var monitoring_1 = require("./monitoring");
Object.defineProperty(exports, "monitorFirestoreQuota", { enumerable: true, get: function () { return monitoring_1.monitorFirestoreQuota; } });
Object.defineProperty(exports, "detectUsageSpikes", { enumerable: true, get: function () { return monitoring_1.detectUsageSpikes; } });
Object.defineProperty(exports, "monitorFunctionPerformance", { enumerable: true, get: function () { return monitoring_1.monitorFunctionPerformance; } });
Object.defineProperty(exports, "dailyHealthReport", { enumerable: true, get: function () { return monitoring_1.dailyHealthReport; } });
Object.defineProperty(exports, "healthCheck", { enumerable: true, get: function () { return monitoring_1.healthCheck; } });
Object.defineProperty(exports, "trackFunctionExecution", { enumerable: true, get: function () { return monitoring_1.trackFunctionExecution; } });
Object.defineProperty(exports, "logError", { enumerable: true, get: function () { return monitoring_1.logError; } });
//# sourceMappingURL=index.js.map