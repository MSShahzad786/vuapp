import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<String> _tableNames = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _columnNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );

      _tableNames = tables
          .map((table) => table['name'] as String)
          .where((name) => !name.startsWith('sqlite_') && !name.startsWith('android_'))
          .toList();

      _tableNames.sort();
    } catch (e) {

      _tableNames = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;
      final data = await db.query(tableName);

      if (data.isNotEmpty) {
        _columnNames = data.first.keys.toList();
        _tableData = data;
      } else {
        // Get column info from pragma
        final pragmaResult = await db.rawQuery('PRAGMA table_info($tableName)');
        _columnNames = pragmaResult.map((col) => col['name'] as String).toList();
        _tableData = [];
      }
    } catch (e) {

      _columnNames = [];
      _tableData = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Table:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedTable,
                    hint: const Text('Choose a table'),
                    items: _tableNames.map((table) {
                      return DropdownMenuItem<String>(
                        value: table,
                        child: Text(table),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTable = value;
                        _tableData = [];
                        _columnNames = [];
                      });
                      if (value != null) {
                        _loadTableData(value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTable != null) ...[
                    Text(
                      'Table: $_selectedTable',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Records: ${_tableData.length}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _tableData.isEmpty && _columnNames.isNotEmpty
                          ? Center(
                              child: Text(
                                'No data in this table',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : _columnNames.isEmpty
                              ? const Center(child: Text('No columns found'))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: _columnNames.map((col) {
                                        return DataColumn(
                                          label: Text(
                                            col,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                      rows: _tableData.map((row) {
                                        return DataRow(
                                          cells: _columnNames.map((col) {
                                            final value = row[col];
                                            return DataCell(
                                              Text(
                                                value?.toString() ?? 'NULL',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
