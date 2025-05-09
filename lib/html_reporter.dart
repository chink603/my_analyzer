// lib/html_reporter.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert' show htmlEscape, jsonEncode; // Add jsonEncode import

// Adjust these imports based on your package name in pubspec.yaml
import 'package:my_analyzer/code_analyzer.dart'; // Assuming package name is 'my_analyzer'
import 'package:my_analyzer/models.dart';

class HtmlReporter {
  // Directory name for individual file reports, relative to the main output directory
  static const String individualReportsSubDir = 'files';

  Future<void> generateReportForProject(
      ProjectAnalysisResult projectResult, String outputBaseDirectoryPath) async { // Renamed for clarity

    // outputBaseDirectoryPath คือ path ที่ถูกสร้าง (หรือมีอยู่แล้ว) โดย analyzer_tool.dart
    final baseDir = Directory(outputBaseDirectoryPath);
    // เราอาจจะไม่จำเป็นต้อง create baseDir ที่นี่อีก ถ้า analyzer_tool จัดการแล้ว
    // แต่การตรวจสอบว่ามีอยู่จริงก็ไม่เสียหาย
    if (!await baseDir.exists()) {
        // ควรจะไม่เกิดกรณีนี้ถ้า analyzer_tool ทำงานถูกต้อง
        print("Error: Base output directory ${baseDir.path} does not exist. Creating it.");
        await baseDir.create(recursive: true);
    }

    // Create/clear the subdirectory for individual file HTMLs
    final individualReportsDirPath = p.join(baseDir.path, individualReportsSubDir);
    final individualReportsDir = Directory(individualReportsDirPath);
    if (await individualReportsDir.exists()) {
      await individualReportsDir.delete(recursive: true);
    }
    await individualReportsDir.create(recursive: true);

    // 1. Generate individual HTML files
  for (final fileResult in projectResult.fileResults) {
      final relativeDartFilePath = p.relative(fileResult.filePath, from: projectResult.directoryPath);

      // ---- START CHANGE 2: Calculate structured output path ----
      // Create the output HTML file path mirroring the source structure
      // Change extension from .dart to .html
      String outputRelativeHtmlPath = p.setExtension(relativeDartFilePath, '.html');

      // Prepend the base subdirectory name for individual files
      final fullIndividualReportPath = p.join(individualReportsDirPath, outputRelativeHtmlPath);

      // Ensure the directory for THIS specific HTML file exists
      final reportFileDir = Directory(p.dirname(fullIndividualReportPath));
      if (!await reportFileDir.exists()) {
        await reportFileDir.create(recursive: true); // Create nested dirs as needed
      }
      // ---- END CHANGE 2 ----

      // Generate the individual file report (this call remains the same)
      await _generateIndividualFileHtml(fileResult, projectResult.directoryPath, fullIndividualReportPath);
    }

    // 2. Generate the main index.html file
    final mainReportFilePath = p.join(baseDir.path, 'index.html');
    await _generateMainIndexHtml(projectResult, mainReportFilePath, individualReportsSubDir);

    print('Report generation complete.');
    print('Main report: ${p.absolute(mainReportFilePath)}'); // แสดง absolute path
    print('Individual file reports in: ${p.absolute(individualReportsDirPath)}'); // แสดง absolute path
  }

   // ... (constants and other methods like generateReportForProject, _generateIndividualFileHtml, _buildFileTree, _writeFileTreeHtml, _writeHtmlHeader, etc. as you provided) ...

  // --- Generates the main index.html (Sidebar + Dashboard + Iframe) ---
  // ** REPLACEMENT FOR THIS METHOD in your file **
  Future<void> _generateMainIndexHtml(ProjectAnalysisResult projectResult, String mainFilePath, String reportsSubDirName) async {
    final buffer = StringBuffer();
    // Pass projectResult to _writeHtmlHeader if it needs data for JS (as in previous examples)
    _writeHtmlHeader(buffer, "Project Complexity Report: ${projectResult.directoryPath}", isIndexPage: true); // Ensure projectResult is passed

    buffer.writeln(
        '<div class="page-container flex min-h-screen bg-slate-50 dark:bg-slate-900 text-slate-800 dark:text-slate-200 antialiased font-sans">');
    
    // --- Sidebar (Keep your existing sidebar generation logic) ---
    buffer.writeln(
        '<aside class="sidebar w-80 bg-white dark:bg-slate-800 border-r border-slate-200 dark:border-slate-700 p-4 fixed top-0 left-0 h-full overflow-y-auto">');
    
    // Add navigation buttons
    buffer.writeln('''
        <div class="flex space-x-2 mb-4">
            <button id="dashboard-nav" class="flex-1 px-3 py-2 text-sm font-medium rounded-md bg-sky-100 dark:bg-sky-900 text-sky-700 dark:text-sky-300 hover:bg-sky-200 dark:hover:bg-sky-800 transition-colors">
                Dashboard
            </button>
            <button id="files-nav" class="flex-1 px-3 py-2 text-sm font-medium rounded-md bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-600 transition-colors">
                Files
            </button>
        </div>
    ''');

    // Add dashboard content in sidebar
    buffer.writeln('''
        <div id="sidebar-dashboard" class="space-y-4">
            <h2 class="text-xl font-semibold text-sky-700 dark:text-sky-400 mb-4 pb-2 border-b border-slate-200 dark:border-slate-700">Dashboard</h2>
            <div class="space-y-3">
                <div class="bg-slate-50 dark:bg-slate-800/50 p-3 rounded-lg">
                    <div class="text-sm font-medium text-slate-500 dark:text-slate-400">Files Analyzed</div>
                    <div class="text-2xl font-bold text-sky-600 dark:text-sky-400 mt-1">${projectResult.totalFilesAnalyzed}</div>
                </div>
                <div class="bg-slate-50 dark:bg-slate-800/50 p-3 rounded-lg">
                    <div class="text-sm font-medium text-slate-500 dark:text-slate-400">Total Issues</div>
                    <div class="text-2xl font-bold ${projectResult.totalIssues > 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'} mt-1">${projectResult.totalIssues}</div>
                </div>
            </div>
        </div>
    ''');

    // File explorer section
    buffer.writeln('<div id="sidebar-files" class="hidden">');
    buffer.writeln(
        '<h2 class="text-xl font-semibold text-sky-700 dark:text-sky-400 mb-4 pb-2 border-b border-slate-200 dark:border-slate-700">Project Explorer</h2>');
    buffer.writeln('<nav id="file-tree" class="text-sm">');
    if (projectResult.fileResults.isEmpty) {
      buffer.writeln('<ul><li class="p-2 text-slate-500">No Dart files found.</li></ul>');
    } else {
      final fileTree = _buildFileTree(projectResult.fileResults, projectResult.directoryPath);
      _writeFileTreeHtml(buffer, fileTree, projectResult.directoryPath, reportsSubDirName: reportsSubDirName);
    }
    buffer.writeln('</nav>');
    buffer.writeln('</aside>');
    
    // --- Main Content ---
    buffer.writeln(
        '<main class="main-content flex-1 p-6 lg:p-8 ml-80 overflow-y-auto">');
    buffer.writeln('<header class="mb-8">');
    buffer.writeln(
        '<h1 class="text-3xl font-bold text-sky-800 dark:text-sky-300">Dart Code Complexity Report</h1>');
    buffer.writeln(
        '<h2 class="text-lg text-slate-600 dark:text-slate-400 mt-1">Project: ${_escapeHtml(projectResult.directoryPath)}</h2>');
    // NOTE: Moved active-file-display closer to iframe below the dashboard
    buffer.writeln('</header>');

    // --- START DASHBOARD SECTION ---
    buffer.writeln('<section id="dashboard" class="mb-8">');
    buffer.writeln('<h3 class="text-2xl font-semibold text-slate-800 dark:text-slate-200 mb-4">Dashboard Summary</h3>');

    // Summary Cards Grid
    buffer.writeln('<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 mb-6">');
    // Files Analyzed Card (Uses getter from ProjectAnalysisResult)
    buffer.writeln('''
        <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-md border border-slate-200 dark:border-slate-700">
            <div class="text-sm font-medium text-slate-500 dark:text-slate-400">Files Analyzed</div>
            <div class="text-3xl font-bold text-sky-600 dark:text-sky-400 mt-1">${projectResult.totalFilesAnalyzed}</div>
        </div>
    ''');
    // Total Issues Card (Uses getter from ProjectAnalysisResult)
    buffer.writeln('''
        <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-md border border-slate-200 dark:border-slate-700">
            <div class="text-sm font-medium text-slate-500 dark:text-slate-400">Total Issues Found</div>
            <div class="text-3xl font-bold ${projectResult.totalIssues > 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'} mt-1">${projectResult.totalIssues}</div>
        </div>
    ''');

    // **** START: Issues by Type Card ****
    final issueCounts = projectResult.issueCountsByType; // Use getter
    if (issueCounts.isNotEmpty) {
      buffer.writeln('''
          <div class="md:col-span-2 lg:col-span-1 xl:col-span-2 bg-white dark:bg-slate-800 p-4 rounded-lg shadow-md border border-slate-200 dark:border-slate-700">
              <div class="text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">Issues by Type</div>
              <ul class="space-y-1">
      ''');
      // Loop through issue types and counts
      issueCounts.forEach((type, count) {
          final typeColorClass = _getIssueTypeColorClass(type); // Use helper for color
          buffer.writeln('''
              <li class="flex justify-between items-center text-sm">
                  <button data-type="issue-type-filter" data-issue-type="${_escapeHtml(type)}" class="$typeColorClass font-medium hover:underline focus:outline-none focus:ring-2 focus:ring-offset-1 dark:focus:ring-offset-slate-800 focus:ring-sky-300 rounded px-1">
                      ${_escapeHtml(type)}
                  </button>
                  <span class="font-semibold $typeColorClass">$count</span>
              </li>
          ''');
      });
      buffer.writeln('</ul></div>');
    }
    // **** END: Issues by Type Card ****

    buffer.writeln('</div>'); // End grid

    // **** START: Placeholder for Issue Type File List ****
    // This section is initially hidden and populated by JavaScript
    buffer.writeln('<div id="issue-type-file-list-container" class="mb-6 hidden">');
    buffer.writeln('<h4 class="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-3" id="issue-type-list-header">Files with Issue: </h4>');
    buffer.writeln('<div id="issue-type-file-list" class="overflow-x-auto rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-md">');
    // Table content will be inserted here by JS
    buffer.writeln('</div>');
    buffer.writeln('<button id="back-to-dashboard" class="mt-3 text-sm text-sky-600 hover:text-sky-800 dark:text-sky-400 dark:hover:text-sky-200 hover:underline">« Back to Dashboard Summary</button>');
    buffer.writeln('</div>');
    // **** END: Placeholder ****

    // --- Files with Most Issues Table Container (Keep your existing logic) ---
    buffer.writeln('<div id="top-files-container">'); // Container ID for showing/hiding
    final topFiles = projectResult.filesSortedByIssues.toList(); // Remove take(10) to get all files
    if (topFiles.isNotEmpty) {
        buffer.writeln('<h4 class="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-3">Top Files with Issues</h4>');
        buffer.writeln('<div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-md">');
        buffer.writeln('<table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700 text-sm">');
        buffer.writeln('<thead class="bg-slate-100 dark:bg-slate-700/50"><tr>');
        buffer.writeln('<th scope="col" class="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-300 tracking-wider">File Path</th>');
        buffer.writeln('<th scope="col" class="px-3 py-3 text-center font-semibold text-slate-700 dark:text-slate-300 tracking-wider">Issue Count</th>');
        buffer.writeln('<th scope="col" class="px-4 py-3 text-center font-semibold text-slate-700 dark:text-slate-300 tracking-wider">Action</th>');
        buffer.writeln('</tr></thead>');
        buffer.writeln('<tbody id="top-files-table-body" class="divide-y divide-slate-200 dark:divide-slate-700">');
        // Table body will be populated by JavaScript
        buffer.writeln('</tbody></table></div>');

        // Add pagination controls
        buffer.writeln('''
            <div class="mt-4 flex items-center justify-between">
                <div class="flex items-center space-x-2">
                    <span class="text-sm text-slate-600 dark:text-slate-400">Show</span>
                    <select id="page-size" class="text-sm border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 px-2 py-1">
                        <option value="10">10</option>
                        <option value="25">25</option>
                        <option value="50">50</option>
                        <option value="100">100</option>
                    </select>
                    <span class="text-sm text-slate-600 dark:text-slate-400">entries</span>
                </div>
                <div class="flex items-center space-x-2">
                    <button id="prev-page" class="px-3 py-1 text-sm font-medium text-slate-600 dark:text-slate-400 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed">
                        Previous
                    </button>
                    <span id="page-info" class="text-sm text-slate-600 dark:text-slate-400"></span>
                    <button id="next-page" class="px-3 py-1 text-sm font-medium text-slate-600 dark:text-slate-400 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed">
                        Next
                    </button>
                </div>
            </div>
        ''');

        // Add JavaScript for pagination
        final filesData = topFiles.map((fileInfo) {
            final fileResult = fileInfo['file'] as FileAnalysisResult;
            final issueCount = fileInfo['issueCount'] as int;
            final relativePath = p.relative(fileResult.filePath, from: projectResult.directoryPath);
            final outputRelativeHtmlPath = p.setExtension(relativePath, '.html');
            final href = p.join(reportsSubDirName, outputRelativeHtmlPath).replaceAll(r'\', '/');
            return {
                'path': relativePath,
                'issueCount': issueCount,
                'href': href,
                'isHighIssues': issueCount > 5,
                'isMediumIssues': issueCount > 0 && issueCount <= 5
            };
        }).toList();

        buffer.writeln('''
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                const topFiles = ${jsonEncode(filesData)};
                
                let currentPage = 1;
                let pageSize = 10;
                const tableBody = document.getElementById('top-files-table-body');
                const pageInfo = document.getElementById('page-info');
                const prevButton = document.getElementById('prev-page');
                const nextButton = document.getElementById('next-page');
                const pageSizeSelect = document.getElementById('page-size');

                function renderTable() {
                    const start = (currentPage - 1) * pageSize;
                    const end = start + pageSize;
                    const pageData = topFiles.slice(start, end);
                    const totalPages = Math.ceil(topFiles.length / pageSize);

                    // Update table
                    tableBody.innerHTML = pageData.map(function(file) {
                        const rowClass = "hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors";
                        const pathCellClass = "px-4 py-2.5 whitespace-nowrap font-medium text-slate-800 dark:text-slate-200";
                        const countCellClass = "px-3 py-2.5 text-center font-semibold " + 
                            (file.isHighIssues ? "text-red-600 dark:text-red-400" : 
                             (file.isMediumIssues ? "text-amber-600 dark:text-amber-400" : 
                              "text-green-600 dark:text-green-400"));
                        const actionCellClass = "px-4 py-2.5 text-center";
                        const buttonClass = "inline-block bg-sky-600 hover:bg-sky-700 text-white text-xs font-semibold px-3 py-1 rounded-md shadow-sm transition-colors";
                        
                        return '<tr class="' + rowClass + '">' +
                               '<td class="' + pathCellClass + '">' + file.path + '</td>' +
                               '<td class="' + countCellClass + '">' + file.issueCount + '</td>' +
                               '<td class="' + actionCellClass + '">' +
                               '<a href="' + file.href + '" target="_blank" rel="noopener noreferrer" data-type="file-link" data-filepath="' + file.path + '" class="' + buttonClass + '">View Details</a>' +
                               '</td></tr>';
                    }).join('');

                    // Update pagination info
                    pageInfo.textContent = 'Page ' + currentPage + ' of ' + totalPages;
                    
                    // Update button states
                    prevButton.disabled = currentPage === 1;
                    nextButton.disabled = currentPage === totalPages;
                }

                // Event listeners
                prevButton.addEventListener('click', function() {
                    if (currentPage > 1) {
                        currentPage--;
                        renderTable();
                    }
                });

                nextButton.addEventListener('click', function() {
                    const totalPages = Math.ceil(topFiles.length / pageSize);
                    if (currentPage < totalPages) {
                        currentPage++;
                        renderTable();
                    }
                });

                pageSizeSelect.addEventListener('change', function() {
                    pageSize = parseInt(this.value);
                    currentPage = 1; // Reset to first page
                    renderTable();
                });

                // Initial render
                renderTable();
            });
        </script>
        ''');
    } else if (projectResult.fileResults.isNotEmpty && issueCounts.isEmpty) {
         buffer.writeln('<p class="text-green-600 dark:text-green-400 font-medium">🎉 No issues found in any analyzed files!</p>');
    }
    buffer.writeln('</div>'); // End top-files-container
    // --- End Files with Most Issues ---

    buffer.writeln('</section>');
    // --- END DASHBOARD SECTION ---

    // --- Iframe Section (Keep your existing logic) ---
    buffer.writeln('<hr class="border-slate-300 dark:border-slate-600 my-6">');
    buffer.writeln(
        '<div id="active-file-display" class="mb-3 text-sm font-medium text-sky-700 dark:text-sky-300 bg-sky-100 dark:bg-sky-800/50 p-2.5 rounded-md">Select a file to view details.</div>');
    buffer.writeln(
        '<iframe id="content-frame" name="content-frame" class="w-full h-[calc(100vh-280px)] border border-slate-300 dark:border-slate-700 rounded-lg shadow-inner bg-white dark:bg-slate-800" srcdoc="<p class=\'p-6 text-slate-500 dark:text-slate-400\'>Select a file from the explorer or dashboard.</p>"></iframe>');
    // --- End Iframe Section ---

    buffer.writeln('</main></div>'); // Close main-content & page-container
    _writeHtmlFooter(buffer);

    // Add JavaScript for navigation
    buffer.writeln('''
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const dashboardNav = document.getElementById('dashboard-nav');
            const filesNav = document.getElementById('files-nav');
            const sidebarDashboard = document.getElementById('sidebar-dashboard');
            const sidebarFiles = document.getElementById('sidebar-files');
            const mainDashboard = document.getElementById('dashboard');
            const contentFrame = document.getElementById('content-frame');
            const activeFileDisplay = document.getElementById('active-file-display');

            function showDashboard() {
                dashboardNav.classList.add('bg-sky-100', 'dark:bg-sky-900', 'text-sky-700', 'dark:text-sky-300');
                dashboardNav.classList.remove('bg-slate-100', 'dark:bg-slate-700', 'text-slate-700', 'dark:text-slate-300');
                filesNav.classList.add('bg-slate-100', 'dark:bg-slate-700', 'text-slate-700', 'dark:text-slate-300');
                filesNav.classList.remove('bg-sky-100', 'dark:bg-sky-900', 'text-sky-700', 'dark:text-sky-300');
                
                sidebarDashboard.classList.remove('hidden');
                sidebarFiles.classList.add('hidden');
                mainDashboard.classList.remove('hidden');
                contentFrame.classList.add('hidden');
                activeFileDisplay.classList.add('hidden');
            }

            function showFiles() {
                filesNav.classList.add('bg-sky-100', 'dark:bg-sky-900', 'text-sky-700', 'dark:text-sky-300');
                filesNav.classList.remove('bg-slate-100', 'dark:bg-slate-700', 'text-slate-700', 'dark:text-slate-300');
                dashboardNav.classList.add('bg-slate-100', 'dark:bg-slate-700', 'text-slate-700', 'dark:text-slate-300');
                dashboardNav.classList.remove('bg-sky-100', 'dark:bg-sky-900', 'text-sky-700', 'dark:text-sky-300');
                
                sidebarFiles.classList.remove('hidden');
                sidebarDashboard.classList.add('hidden');
                mainDashboard.classList.add('hidden');
                contentFrame.classList.remove('hidden');
                activeFileDisplay.classList.remove('hidden');
            }

            dashboardNav.addEventListener('click', showDashboard);
            filesNav.addEventListener('click', showFiles);

            // Show dashboard by default
            showDashboard();
        });
    </script>
    ''');

    await File(mainFilePath).writeAsString(buffer.toString());
  }
  // --- Make sure you have this helper method ---
  String _getIssueTypeColorClass(String issueType) {
     switch (issueType) {
      case 'High Cyclomatic Complexity': case 'High Cognitive Complexity':
      case 'Long Function': case 'Many Parameters': case 'Deep Nesting':
        return 'text-red-600 dark:text-red-400';
      case 'Pending Task':
        return 'text-amber-600 dark:text-amber-400';
      default: return 'text-slate-600 dark:text-slate-400';
    }
  }
  // --- Generates an HTML file for a single analyzed Dart file ---
  Future<void> _generateIndividualFileHtml(FileAnalysisResult fileResult, String projectBasePath, String outputFilePath) async {
    final buffer = StringBuffer();
    final relativePath = p.relative(fileResult.filePath, from: projectBasePath);
    // Pass isIndexPage: false to _writeHtmlHeader for individual file pages
    _writeHtmlHeader(buffer, "Report: ${_escapeHtml(relativePath)}", isIndexPage: false);

    // For individual file pages, we only need the body content for the file-section
    buffer.writeln('<body class="font-sans bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 p-0 m-0">'); // Minimal body for iframe
    _writeFileReportSection(buffer, fileResult, projectBasePath); // isHidden is not relevant here
    buffer.writeln('</body>');
    _writeHtmlFooter(buffer);
    await File(outputFilePath).writeAsString(buffer.toString());
  }

  Map<String, dynamic> _buildFileTree(List<FileAnalysisResult> files, String projectBasePath) {
    final tree = <String, dynamic>{};
    for (final fileResult in files) {
      final relativePath = p.relative(fileResult.filePath, from: projectBasePath);
      final parts = p.split(relativePath);
      Map<String, dynamic> currentNode = tree;
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1) {
          currentNode.putIfAbsent('_files', () => <Map<String,dynamic>>[]);
          (currentNode['_files'] as List).add({'name': part, 'fullPath': relativePath, 'data': fileResult});
        } else {
          currentNode = currentNode.putIfAbsent(part, () => <String, dynamic>{});
        }
      }
    }
    return tree;
  }

  // Modified to accept reportsSubDirName for link generation
  void _writeFileTreeHtml(StringBuffer buffer, Map<String, dynamic> treeNode, String projectBasePath, {int depth = 0, required String reportsSubDirName}) {
    buffer.writeln('<ul class="${depth > 0 ? 'ml-4' : ''} space-y-0.5">');
    final sortedKeys = treeNode.keys.toList()..sort((a, b) {
      bool isADir = a != '_files' && treeNode[a] is Map;
      bool isBDir = b != '_files' && treeNode[b] is Map;
      if (isADir && !isBDir) return -1; if (!isADir && isBDir) return 1; return a.compareTo(b);
    });

    for (final key in sortedKeys) {
      if (key == '_files') continue;
      final nodeValue = treeNode[key];
      if (nodeValue is Map<String, dynamic>) {
        buffer.writeln('<li class="directory-node">');
        buffer.writeln(
            '<div data-type="toggler" class="flex items-center cursor-pointer p-1.5 rounded hover:bg-sky-100 dark:hover:bg-slate-700">');
        buffer.writeln(
            '<svg class="icon-toggler w-4 h-4 mr-2 text-slate-500 dark:text-slate-400 transition-transform duration-150" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>');
        buffer.writeln(
            '<span class="folder-name font-medium text-sm text-slate-700 dark:text-slate-300">${_escapeHtml(key)}</span>');
        buffer.writeln('</div>');
        buffer.writeln('<div class="sub-tree" style="display: none;">');
        _writeFileTreeHtml(buffer, nodeValue, projectBasePath, depth: depth + 1, reportsSubDirName: reportsSubDirName);
        buffer.writeln('</div></li>');
      }
    }
    if (treeNode.containsKey('_files')) {
      final files = treeNode['_files'] as List<Map<String,dynamic>>;
      files.sort((a,b) => (a['name'] as String).compareTo(b['name'] as String));
      for (final fileEntry in files) {
        final fileName = fileEntry['name'] as String;
        final fullRelativePath = fileEntry['fullPath'] as String;
        final fileData = fileEntry['data'] as FileAnalysisResult;
          final outputRelativeHtmlPath = p.setExtension(fullRelativePath, '.html');
        // Generate href for the individual file report
        // final individualFileName = _sanitizeForId(fullRelativePath) + '.html';
        final href = p.join(reportsSubDirName, outputRelativeHtmlPath); // Path relative to index.html
        final webHref = href.replaceAll(r'\', '/');
        num issuesInFile = fileData.fileLevelIssues.length + fileData.functions.fold(0, (s, f) => s + f.issues.length) + fileData.classes.fold(0, (s, c) => s + c.issues.length + c.methods.fold(0, (ms, m) => ms + m.issues.length));
        String issueBorderClass = issuesInFile == 0 ? 'border-l-transparent' : (issuesInFile < 5 ? 'border-l-amber-400' : 'border-l-red-500');
        
       buffer.writeln('<li class="file-node">');
        buffer.writeln(
            // Use the correctly calculated webHref
            '<a href="${_escapeHtml(webHref)}" target="content-frame" data-type="file-link" data-filepath="${_escapeHtml(fullRelativePath)}" class="block p-1.5 pl-5 text-sm text-slate-600 dark:text-slate-400 rounded hover:bg-sky-100 dark:hover:bg-slate-700 hover:text-sky-700 dark:hover:text-sky-300 border-l-2 $issueBorderClass transition-colors duration-150">');
        buffer.writeln(_escapeHtml(fileName));
        if (issuesInFile > 0) {
          buffer.writeln(
              '<span class="ml-1 text-xs px-1.5 py-0.5 rounded-full ${issuesInFile < 5 ? "bg-amber-200 text-amber-800 dark:bg-amber-700 dark:text-amber-100" : "bg-red-200 text-red-800 dark:bg-red-700 dark:text-red-100"}">$issuesInFile</span>');
        }
        buffer.writeln('</a></li>');
      }
    }
    buffer.writeln('</ul>');
  }

  String _sanitizeForId(String path) => path.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  // Modified to accept isIndexPage to conditionally include JS and different body/style
  void _writeHtmlHeader(StringBuffer buffer, String title, {required bool isIndexPage,}) {
    buffer.writeln('<!DOCTYPE html><html lang="en" class="scroll-smooth">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${_escapeHtml(title)}</title>');
    buffer.writeln('  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">');
    buffer.writeln('  <script src="https://cdn.tailwindcss.com"></script>');
    buffer.writeln('''<style type="text/tailwindcss">
        /* Common styles used by both index and individual pages */
        .code-snippet-container { margin-top: 0.75rem; }
        .code-snippet-container pre { @apply bg-slate-100 dark:bg-slate-700/50 p-3 rounded-md overflow-x-auto text-xs; }
        .code-snippet-container code { @apply font-mono; }
        /* Specific styles for file sections when viewed directly or in iframe */
        .file-section { @apply bg-white dark:bg-slate-800 shadow-xl rounded-xl p-6 md:p-8; }
        /* Styles for the index page (sidebar interactivity) */
        ${isIndexPage ? '''
        .directory-node.expanded > div[data-type="toggler"] > .icon-toggler { transform: rotate(90deg); }
        ''' : '''
        /* Styles for individual report pages if different from index's body */
        body.individual-report-page { @apply p-0 m-0; } 
        .file-section { @apply mb-0 rounded-none shadow-none; } /* No margin/shadow for iframe content */
        '''}
    </style>''');

    if (isIndexPage) {
      // JavaScript for sidebar interactivity, only for the main index.html
      buffer.writeln('''
      <script>
        document.addEventListener('DOMContentLoaded', function () {
          const fileTreeNav = document.getElementById('file-tree');
          const activeFileDisplay = document.getElementById('active-file-display');
          const contentFrame = document.getElementById('content-frame');
          let currentActiveLink = null;

          if (fileTreeNav) {
            fileTreeNav.addEventListener('click', function(event) {
              const clickedElement = event.target;
              const togglerDiv = clickedElement.closest('div[data-type="toggler"]');
              if (togglerDiv) {
                const parentDirNode = togglerDiv.closest('.directory-node');
                if (parentDirNode) {
                  parentDirNode.classList.toggle('expanded');
                  const subTree = parentDirNode.querySelector('.sub-tree');
                  if (subTree) subTree.style.display = parentDirNode.classList.contains('expanded') ? 'block' : 'none';
                }
              }

              const fileLink = clickedElement.closest('a[data-type="file-link"]');
              if (fileLink) { // href will navigate the iframe via target attribute
                // No event.preventDefault(); needed
                const filePath = fileLink.dataset.filepath;
                if (currentActiveLink) {
                  currentActiveLink.classList.remove('bg-sky-200', 'dark:bg-sky-700', 'text-sky-700', 'dark:text-sky-200', 'font-semibold');
                }
                fileLink.classList.add('bg-sky-200', 'dark:bg-sky-700', 'text-sky-700', 'dark:text-sky-200', 'font-semibold');
                currentActiveLink = fileLink;

                if(activeFileDisplay && filePath) activeFileDisplay.textContent = 'Viewing: ' + _escapeHtmlJS(filePath);
                // contentFrame.src = fileLink.href; // This is handled by target attribute now
              }
            });
          }

          const firstLevelDirs = fileTreeNav ? fileTreeNav.querySelectorAll(':scope > ul > .directory-node') : [];
          firstLevelDirs.forEach(dir => {
            dir.classList.add('expanded');
            const subTree = dir.querySelector('.sub-tree');
            if (subTree) subTree.style.display = 'block';
          });
          
          const firstFileLink = fileTreeNav ? fileTreeNav.querySelector('.file-node a[data-type="file-link"]') : null;
          if (firstFileLink && contentFrame) {
             // Trigger a click to set active state and update display text
             // The href will automatically load into the iframe due to target="content-frame"
            firstFileLink.click(); 
          } else if (activeFileDisplay) {
            activeFileDisplay.textContent = 'No files found or analyzed.';
          }
        });
      </script>
      ''');
    }
    buffer.writeln('</head>');
    // Body tag itself will be written by _generateMainIndexHtml or _generateIndividualFileHtml
  }

  void _writeHtmlFooter(StringBuffer buffer) => buffer.writeln('</html>');

  // This method now generates ONLY the content section for a file
  // It will be used for individual HTML pages and potentially by a fetch-based SPA approach later
  void _writeFileReportSection(StringBuffer buffer, FileAnalysisResult result, String projectBasePath) {
    final relativePath = p.relative(result.filePath, from: projectBasePath);
    // The id attribute is removed from here as it's not needed when content is in its own file
    // If you switch to a fetch-based SPA, you might add it back to a wrapper div in index.html
    buffer.writeln('<div class="file-section">'); // This div will be the root of the content in individual files
    buffer.writeln(
        '<h2 class="text-2xl font-semibold text-sky-700 dark:text-sky-300 mb-6 pb-3 border-b border-slate-200 dark:border-slate-700">${_escapeHtml(relativePath)}</h2>');
    if (result.fileLevelIssues.isNotEmpty) {
      buffer.writeln(
          '<h3 class="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-3 mt-5">File-Level Issues:</h3>');
      buffer.writeln('<div class="space-y-3">');
      for (final issue in result.fileLevelIssues) _writeIssue(buffer, issue);
      buffer.writeln('</div>');
    }
    if (result.classes.isNotEmpty) {
      buffer.writeln(
          '<h3 class="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-4 mt-6">Classes</h3>');
      buffer.writeln('<div class="space-y-6">');
      for (final classMetric in result.classes) {
        buffer.writeln(
            '<div class="class-summary border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-slate-50 dark:bg-slate-800/50">');
        buffer.writeln(
            '<h4 class="text-lg font-medium text-sky-600 dark:text-sky-400 mb-1">Class: ${_escapeHtml(classMetric.name)} <span class="text-xs font-normal text-slate-500 dark:text-slate-400">(Lines: ${classMetric.startLine}-${classMetric.endLine})</span></h4>');
        if (classMetric.issues.isNotEmpty) {
           buffer.writeln('<div class="mt-2 space-y-2">');
           for (final issue in classMetric.issues) _writeIssue(buffer, issue);
           buffer.writeln('</div>');
        }
        if (classMetric.methods.isNotEmpty) {
          buffer.writeln('<div class="mt-3">');
          _writeFunctionTable(buffer, classMetric.methods, isMethod: true);
          buffer.writeln('</div>');
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }
    if (result.functions.isNotEmpty) {
      buffer.writeln(
          '<h3 class="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-4 mt-6">Top-Level Functions</h3>');
      _writeFunctionTable(buffer, result.functions, isMethod: false);
    }
    if (result.classes.isEmpty && result.functions.isEmpty && result.fileLevelIssues.isEmpty) {
      buffer.writeln(
          '<p class="text-slate-500 dark:text-slate-400">No specific issues or complex structures found.</p>');
    }
    buffer.writeln('</div>');
  }

  String _getTailwindMetricTextColor(int value, double thresholdWarn, double thresholdHigh) {
    if (thresholdHigh > 0 && value >= thresholdHigh) return 'text-red-600 dark:text-red-400 font-semibold';
    if (thresholdWarn > 0 && value >= thresholdWarn) return 'text-amber-600 dark:text-amber-400';
    return 'text-green-600 dark:text-green-400';
  }

  void _writeFunctionTable(StringBuffer buffer, List<FunctionMetric> functions, {required bool isMethod}) {
    // Your existing _writeFunctionTable implementation (with Tooltips for headers)
    // Ensure it's correctly placed here.
    // This is the version from your provided code, with the tooltip logic added.
    buffer.writeln(
        '<div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-slate-700">');
    buffer.writeln(
        '<table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700 text-sm">');
    buffer.writeln('<thead class="bg-slate-100 dark:bg-slate-700/50"><tr>');
    buffer.writeln(
        '<th scope="col" class="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-300 tracking-wider">${isMethod ? "Method" : "Function"}</th>');
    buffer.writeln(
        '<th scope="col" class="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-300 tracking-wider">Lines</th>');
    final Map<String, String> metricHeaders = {
      'LOC': 'Lines of Code', 'CC': 'Cyclomatic Complexity', 'CogC': 'Cognitive Complexity',
      'Params': 'Parameters', 'Nesting': 'Max Nesting Depth'
    };
    for (var entry in metricHeaders.entries) {
      buffer.writeln(
          '<th scope="col" title="${_escapeHtml(entry.value)}" class="px-3 py-3 text-center font-semibold text-slate-700 dark:text-slate-300 tracking-wider cursor-help">${entry.key}</th>');
    }
    buffer.writeln('</tr></thead>');
    buffer.writeln(
        '<tbody class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700">');
    for (final funcMetric in functions) {
      buffer.writeln(
          '<tr class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors">');
      buffer.writeln(
          '<td class="px-4 py-2.5 whitespace-nowrap text-slate-800 dark:text-slate-200 font-medium">${_escapeHtml(funcMetric.name)}</td>');
      buffer.writeln(
          '<td class="px-4 py-2.5 whitespace-nowrap text-slate-500 dark:text-slate-400">${funcMetric.startLine}-${funcMetric.endLine}</td>');
      buffer.writeln(
          '<td class="px-3 py-2.5 text-center ${_getTailwindMetricTextColor(funcMetric.loc, CodeAnalyzer.maxFunctionLoc * 0.7, CodeAnalyzer.maxFunctionLoc.toDouble())}">${funcMetric.loc}</td>');
      buffer.writeln(
          '<td class="px-3 py-2.5 text-center ${_getTailwindMetricTextColor(funcMetric.cyclomaticComplexity, CodeAnalyzer.maxCyclomaticComplexity * 0.7, CodeAnalyzer.maxCyclomaticComplexity.toDouble())}">${funcMetric.cyclomaticComplexity}</td>');
      const double cogCThresholdWarn = 10.0;
      const double cogCThresholdHigh = 15.0;
      buffer.writeln(
          '<td class="px-3 py-2.5 text-center ${_getTailwindMetricTextColor(funcMetric.cognitiveComplexity, cogCThresholdWarn, cogCThresholdHigh)}">${funcMetric.cognitiveComplexity}</td>');
      buffer.writeln(
          '<td class="px-3 py-2.5 text-center ${_getTailwindMetricTextColor(funcMetric.parameterCount, CodeAnalyzer.maxParameters * 0.7, CodeAnalyzer.maxParameters.toDouble())}">${funcMetric.parameterCount}</td>');
      buffer.writeln(
          '<td class="px-3 py-2.5 text-center ${_getTailwindMetricTextColor(funcMetric.maxNestingDepth, CodeAnalyzer.maxNestingDepth * 0.7, CodeAnalyzer.maxNestingDepth.toDouble())}">${funcMetric.maxNestingDepth}</td>');
      buffer.writeln('</tr>');
      if (funcMetric.issues.isNotEmpty) {
        int numberOfColumns = 2 + metricHeaders.length;
        buffer.writeln(
            '<tr class="bg-slate-50 dark:bg-slate-800/30"><td colspan="${numberOfColumns}" class="px-4 py-3">');
        buffer.writeln('<div class="space-y-2">');
        for (final issue in funcMetric.issues) { _writeIssue(buffer, issue); }
        buffer.writeln('</div></td></tr>');
      }
    }
    buffer.writeln('</tbody></table></div>');
  }

  void _writeIssue(StringBuffer buffer, Issue issue) {
    // Your existing _writeIssue implementation
    // Make sure it uses the corrected _escapeHtml
    final String baseBorder, baseBg, baseText, accentText;
    switch (issue.type) {
      case 'High Cyclomatic Complexity': case 'Long Function': case 'Many Parameters': case 'Deep Nesting':
        baseBorder = 'border-red-500 dark:border-red-400'; baseBg = 'bg-red-50 dark:bg-red-900/20';
        baseText = 'text-red-700 dark:text-red-300'; accentText = 'text-red-800 dark:text-red-200'; break;
      case 'Pending Task':
        baseBorder = 'border-amber-500 dark:border-amber-400'; baseBg = 'bg-amber-50 dark:bg-amber-900/20';
        baseText = 'text-amber-700 dark:text-amber-300'; accentText = 'text-amber-800 dark:text-amber-200'; break;
      default:
        baseBorder = 'border-slate-400 dark:border-slate-500'; baseBg = 'bg-slate-100 dark:bg-slate-700/20';
        baseText = 'text-slate-700 dark:text-slate-300'; accentText = 'text-slate-800 dark:text-slate-200';
    }
    buffer.writeln(
        '<div class="issue border-l-4 $baseBorder $baseBg p-3 rounded-r-md">');
    buffer.writeln(
        '<p class="message font-medium text-sm $accentText"><strong class="mr-1">[L${issue.lineNumber}] ${_escapeHtml(issue.type)}:</strong> ${_escapeHtml(issue.message)}</p>');
    buffer.writeln(
        '<p class="suggestion mt-1 text-xs $baseText opacity-90"><em>Suggestion:</em> ${_escapeHtml(issue.suggestion)}</p>');
    if (issue.codeSnippet != null && issue.codeSnippet!.isNotEmpty) {
      buffer.writeln('<div class="code-snippet-container">');
      buffer.writeln(
          '<pre><code class="language-dart">${_escapeHtml(issue.codeSnippet)}</code></pre>');
      buffer.writeln('</div>');
    }
    buffer.writeln('</div>');
  }

  // Using htmlEscape from dart:convert for safety and correctness
  String _escapeHtml(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }
    return htmlEscape.convert(text);
  }
}