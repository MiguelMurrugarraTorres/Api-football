// Estado mostrado (texto + tipo para color)
enum StatusKind { live, time, suspended, other }

class StatusDisplay {
  final String text;
  final StatusKind kind;
  const StatusDisplay(this.text, this.kind);
}
