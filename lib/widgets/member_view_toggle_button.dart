import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/auth_service.dart';
import 'bottom_navigation_wrapper.dart';

class MemberViewToggleButton extends StatefulWidget {
  final VoidCallback? onToggle;

  const MemberViewToggleButton({
    Key? key,
    this.onToggle,
  }) : super(key: key);

  @override
  State<MemberViewToggleButton> createState() => _MemberViewToggleButtonState();
}

class _MemberViewToggleButtonState extends State<MemberViewToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleToggle,
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vue Membre',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleToggle() async {
    try {
      // Haptic feedback
      // HapticFeedback.lightImpact();

      // Afficher un dialog de confirmation
      final shouldToggle = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Basculer vers la vue Membre'),
          content: const Text(
            'Voulez-vous basculer vers la vue Membre ? '
            'Vous pourrez revenir à la vue Admin à tout moment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Basculer'),
            ),
          ],
        ),
      );

      if (shouldToggle == true) {
        // Déclencher le basculement
        if (widget.onToggle != null) {
          widget.onToggle!();
        } else {
          // Basculement par défaut
          await _performDefaultToggle();
        }
      }
    } catch (e) {
      print('Erreur lors du basculement vers la vue Membre: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du basculement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performDefaultToggle() async {
    // Naviguer vers la vue membre
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
        ),
        (route) => false,
      );
    }
  }
}

// Widget alternatif pour un bouton plus simple
class SimpleMemberViewToggleButton extends StatelessWidget {
  final VoidCallback? onToggle;

  const SimpleMemberViewToggleButton({
    Key? key,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleToggle(context),
      icon: Icon(
        Icons.person,
        color: Theme.of(context).primaryColor,
      ),
      tooltip: 'Basculer vers la vue Membre',
    );
  }

  void _handleToggle(BuildContext context) async {
    try {
      if (onToggle != null) {
        onToggle!();
      } else {
        // Basculement par défaut vers le dashboard membre
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur lors du basculement vers la vue Membre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du basculement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Widget pour afficher dans la AppBar
class AppBarMemberViewToggle extends StatelessWidget {
  final VoidCallback? onToggle;

  const AppBarMemberViewToggle({
    Key? key,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _handleToggle(context),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vue Membre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleToggle(BuildContext context) async {
    try {
      if (onToggle != null) {
        onToggle!();
      } else {
        // Basculement par défaut vers le dashboard membre
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur lors du basculement vers la vue Membre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du basculement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}