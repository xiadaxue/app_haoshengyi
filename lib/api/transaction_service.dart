import 'package:haoshengyi_jzzs_app/api/http_client.dart';
import 'package:haoshengyi_jzzs_app/constants/api_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';

/// 交易记录服务类，处理账单记录相关功能
class TransactionService {
  final HttpClient _httpClient = HttpClient();

  /// 创建账单记录
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      final data = await _httpClient.post(
        ApiConstants.transactions,
        data: transaction.toJson(),
      );

      return data['transactionId'];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取账单记录列表
  Future<Map<String, dynamic>> getTransactions({
    String? startDate,
    String? endDate,
    String? type,
    String? category,
    List<String>? tags,
    List<String>? users,
    int page = 1,
    int pageSize = 20,
    String? sort,
    String? fields,
  }) async {
    try {
      final data = await _httpClient.get(
        ApiConstants.transactions,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (type != null) 'type': type,
          if (category != null) 'category': category,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (users != null && users.isNotEmpty) 'users': users.join(','),
          'page': page,
          'pageSize': pageSize,
          if (sort != null) 'sort': sort,
          if (fields != null) 'fields': fields,
        },
      );

      final transactions = (data['transactions'] as List)
          .map((item) => TransactionModel.fromJson(item))
          .toList();

      return {
        'total': data['total'],
        'page': data['page'],
        'pageSize': data['pageSize'],
        'transactions': transactions,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// 获取账单记录详情
  Future<TransactionModel> getTransactionDetail(String transactionId) async {
    try {
      final data =
          await _httpClient.get('${ApiConstants.transactions}/$transactionId');
      return TransactionModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// 更新账单记录
  Future<String> updateTransaction(
      String transactionId, TransactionModel transaction) async {
    try {
      final data = await _httpClient.put(
        '${ApiConstants.transactions}/$transactionId',
        data: transaction.toJson(),
      );

      return data['updated_at'];
    } catch (e) {
      rethrow;
    }
  }

  /// 删除账单记录
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _httpClient.delete('${ApiConstants.transactions}/$transactionId');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取今日收支统计
  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      // 获取今天的日期，格式为 YYYY-MM-DD
      final today = DateTime.now().toIso8601String().split('T')[0];

      final data = await getTransactions(
        startDate: today,
        endDate: today,
      );

      // 计算收入、支出和利润
      double income = 0;
      double expense = 0;

      for (final transaction
          in data['transactions'] as List<TransactionModel>) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expense += transaction.amount;
        }
      }

      return {
        'income': income,
        'expense': expense,
        'profit': income - expense,
        'date': today,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// 获取可用的月份列表
  Future<List<String>> getAvailableMonths() async {
    try {
      final data = await _httpClient.get(
        ApiConstants.availableMonths,
      );

      return (data['months'] as List).cast<String>();
    } catch (e) {
      rethrow;
    }
  }

  /// 获取特定日期范围内有交易的日期列表（仅用于日历展示）
  Future<Map<String, dynamic>> getDatesWithTransactions({
    required String startDate,
    required String endDate,
  }) async {
    try {
      // 调用现有接口，但只请求日期字段
      final data = await _httpClient.get(
        '${ApiConstants.transactions}/dates',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      // 如果后端接口不支持，可以模拟一个实现
      if (data['dates'] == null) {
        // 获取原始交易数据
        final transactions = await getTransactions(
          startDate: startDate,
          endDate: endDate,
          fields: 'transactionDate', // 只获取日期字段，减少数据量
        );

        // 提取不重复的日期
        final Set<String> uniqueDates = {};
        for (var transaction in transactions['transactions']) {
          final date = transaction.transactionDate.split('T')[0];
          uniqueDates.add(date);
        }

        return {
          'dates': uniqueDates.toList(),
        };
      }

      return data;
    } catch (e) {
      print('获取日期列表失败: $e');
      return {'dates': []};
    }
  }
}
