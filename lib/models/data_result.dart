class DataResult<T> {
  final T data;
  final bool isOffline;

  DataResult(this.data, {this.isOffline = false});
}
