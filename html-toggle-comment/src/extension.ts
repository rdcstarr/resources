import * as vscode from "vscode";

export function activate(context: vscode.ExtensionContext) {
	// Register custom command
	const disposable = vscode.commands.registerCommand("extension.toggleHtmlLikeComment", async () => {
		const editor = vscode.window.activeTextEditor;

		if (!editor) {
			return;
		}

		// Positions where we want to move the cursor after the edit
		const positionsToFocus: vscode.Position[] = [];

		await editor.edit((editBuilder) => {
			editor.selections.forEach((selection) => {
				const document = editor.document;
				let range: vscode.Range;

				// If no selection, use the whole current line
				if (selection.isEmpty) {
					const line = document.lineAt(selection.active.line);
					range = line.range;
				} else {
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
				} else {
					if (trimmed.length === 0) {
						// Empty line: create <!--  --> and move cursor inside
						const commentText = "<!--  -->";
						const newText = leftPadding + commentText;
						editBuilder.replace(range, newText);

						// Cursor after "<!-- "
						const cursorColumn = leftPadding.length + 5; // "<!-- ".length = 5
						const cursorPos = new vscode.Position(range.start.line, cursorColumn);
						positionsToFocus.push(cursorPos);
					} else {
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

export function deactivate() {
	// Nothing to clean up
}
