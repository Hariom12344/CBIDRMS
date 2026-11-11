class TrendPointModel {
  final String bucket;
  final double value;

  TrendPointModel({
    required this.bucket,
    required this.value,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      bucket: json['bucket'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'bucket': bucket,
        'value': value,
      };
}

class TrendSeriesModel {
  final String metric;
  final List<TrendPointModel> points;
  final String? status;

  TrendSeriesModel({
    required this.metric,
    required this.points,
    this.status,
  });

  factory TrendSeriesModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? [];
    return TrendSeriesModel(
      metric: json['metric'] ?? '',
      points: rawPoints.map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>)).toList(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'points': points.map((p) => p.toJson()).toList(),
        'status': status,
      };
}
