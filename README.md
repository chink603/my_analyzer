# 📊 my_analyzer

**my_analyzer** is a static analysis tool for Dart that evaluates code complexity and generates interactive HTML reports. It helps developers identify areas of code that are overly complex, hard to understand, or may require refactoring.

---

## ✨ Features

- **Code Complexity Metrics**
  - **Cyclomatic Complexity (CC)** — Measures structural complexity of functions/methods.
  - **Cognitive Complexity (CogC)** — (Preliminary) Estimates the mental effort needed to understand the code.
  - **Lines of Code (LOC)** — Counts lines per function/method.
  - **Number of Parameters** — Counts function/method parameters.
  - **Max Nesting Depth** — Measures how deeply control structures are nested.

- **TODO/FIXME Detection**
  - Highlights comments indicating unfinished or problematic code.

- **Interactive HTML Report**
  - Clean, modern UI powered by Tailwind CSS (via CDN).
  - Sidebar with project file structure for easy navigation.
  - Each file has a dedicated HTML report, embedded using `iframe`.
  - Shows relevant code snippets for each issue found.
  - Tooltips explain all metrics for quick understanding.

- **Full Project Analysis**
  - Analyzes all `.dart` files under a specified directory.
  - Excludes directories like `.dart_tool`, `build`, and platform folders.

---

## 🚀 Installation

In your `pubspec.yaml`, add:

```yaml
dev_dependencies:
  my_analyzer:
    git:
      url: https://github.com/chink603/my_analyzer.git
      ref: master
```

Then run:

```bash
dart pub get
```

---

## ⚙️ Usage

Run the tool from Dart CLI:

```bash
dart run my_analyzer:analyzer_tool -d lib/
```

### Options

- `-d, --directory`: **(Required)** Directory containing your Dart project.
- `-o, --output-dir`: *(Optional)* Output directory for the HTML report.  
  Default: `complexity_report_output`
- `-h, --help`: Show help message.

### Example Commands

```bash
# Analyze the project and output to the default report directory
dart run my_analyzer:analyzer_tool -d path/to/my_dart_app

# Output report to a custom directory
dart run my_analyzer:analyzer_tool -d path/to/my_dart_app -o my_app_report
```

After analysis, open `index.html` in the output directory (e.g., `complexity_report_output/index.html`) in your browser.

---

## 📁 Report Structure

```
<output_directory>/
├── index.html              # Main report with sidebar and iframe viewer
└── files/                  # Individual file reports
    ├── lib/
    │   ├── main.html
    │   └── src/
    │       └── utils/
    │           └── helpers.html
    └── ...
```

---

## 🔭 Roadmap

- [ ] Improve accuracy of Cognitive Complexity (align with SonarSource standards)
- [ ] Add more metrics (e.g., Halstead, Maintainability Index)
- [ ] YAML-based configuration for thresholds and options
- [ ] CLI/config support for excluding files/directories
- [ ] Use `fetch` instead of `iframe` for more flexible report rendering
- [ ] Add syntax highlighting to code snippets (e.g., Prism.js or Highlight.js)
- [ ] Detect code duplication
- [ ] Publish on [pub.dev](https://pub.dev)

---

## 🤝 Contributing

We welcome contributions! Feel free to:

- Fork this repository
- Create a pull request
- Open issues for bugs or feature suggestions

> Please follow the project's coding conventions. Test your changes before submitting PRs.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.