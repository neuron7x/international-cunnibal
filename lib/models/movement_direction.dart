enum MovementDirection { steady, up, down, left, right }

extension MovementDirectionLabel on MovementDirection {
  String get label {
    switch (this) {
      case MovementDirection.up:
        return 'up';
      case MovementDirection.down:
        return 'down';
      case MovementDirection.left:
        return 'left';
      case MovementDirection.right:
        return 'right';
      case MovementDirection.steady:
        return 'steady';
    }
  }

  static MovementDirection fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'up':
        return MovementDirection.up;
      case 'down':
        return MovementDirection.down;
      case 'left':
        return MovementDirection.left;
      case 'right':
        return MovementDirection.right;
      case 'steady':
      default:
        return MovementDirection.steady;
    }
  }
}
