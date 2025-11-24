"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
function activate(context) {
    // Register custom command
    const disposable = vscode.commands.registerCommand("extension.toggleHtmlLikeComment", async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            return;
        }
        // Positions where we want to move the cursor after the edit
        const positionsToFocus = [];
        await editor.edit((editBuilder) => {
            editor.selections.forEach((selection) => {
                const document = editor.document;
                let range;
                // If no selection, use the whole current line
                if (selection.isEmpty) {
                    const line = document.lineAt(selection.active.line);
                    range = line.range;
                }
                else {
                    range = new vscode.Range(selection.start, selection.end);
                }
                const text = document.getText(range);
                const trimmed = text.trim();
                // Compute left and right padding around trimmed text
                const startIndex = text.indexOf(trimmed);
                const leftPadding = trimmed.length === 0 ? text : text.substring(0, startIndex);
                const rightPadding = trimmed.length === 0 ? "" : text.substring(startIndex + trimmed.length);
                const isAlreadyCommented = trimmed.startsWith("<!--") && trimmed.endsWith("-->");
                if (isAlreadyCommented) {
                    // Remove <!-- and --> from the trimmed text
                    let inner = trimmed.substring(4, trimmed.length - 3);
                    // Remove one leading space if present
                    if (inner.startsWith(" ")) {
                        inner = inner.substring(1);
                    }
                    // Remove one trailing space if present
                    if (inner.endsWith(" ")) {
                        inner = inner.substring(0, inner.length - 1);
                    }
                    const newText = leftPadding + inner + rightPadding;
                    editBuilder.replace(range, newText);
                }
                else {
                    if (trimmed.length === 0) {
                        // Empty line: create <!--  --> and move cursor inside
                        const commentText = "<!--  -->";
                        const newText = leftPadding + commentText;
                        editBuilder.replace(range, newText);
                        // Cursor after "<!-- "
                        const cursorColumn = leftPadding.length + 5; // "<!-- ".length = 5
                        const cursorPos = new vscode.Position(range.start.line, cursorColumn);
                        positionsToFocus.push(cursorPos);
                    }
                    else {
                        // Non-empty: wrap trimmed text in <!-- -->
                        const newText = leftPadding + "<!-- " + trimmed + " -->" + rightPadding;
                        editBuilder.replace(range, newText);
                    }
                }
            });
        });
        // After edit is applied, move cursor(s) where needed
        if (positionsToFocus.length > 0) {
            const newSelections = positionsToFocus.map((pos) => new vscode.Selection(pos, pos));
            editor.selections = newSelections;
            // Ensure the first cursor is visible
            editor.revealRange(new vscode.Range(positionsToFocus[0], positionsToFocus[0]));
        }
    });
    context.subscriptions.push(disposable);
}
function deactivate() {
    // Nothing to clean up
}
//# sourceMappingURL=extension.js.map