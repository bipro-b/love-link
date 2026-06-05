import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CallControlBtn extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const CallControlBtn({
    super.key,
    required this.icon,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  State<CallControlBtn> createState() => _CallControlBtnState();
}

class _CallControlBtnState extends State<CallControlBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: .88).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? AppColors.rose;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive
                ? activeCol.withOpacity(.25)
                : Colors.white.withOpacity(.1),
            border: Border.all(
              color: widget.isActive ? activeCol : Colors.white.withOpacity(.15),
              width: 1.5,
            ),
            boxShadow: widget.isActive
                ? [BoxShadow(color: activeCol.withOpacity(.3), blurRadius: 10)]
                : [],
          ),
          child: Icon(
            widget.icon,
            color: widget.isActive ? activeCol : Colors.white.withOpacity(.85),
            size: 22,
          ),
        ),
      ),
    );
  }
}
