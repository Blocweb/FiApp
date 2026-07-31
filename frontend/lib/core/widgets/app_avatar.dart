import 'package:flutter/material.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Avatar circular con las iniciales del cliente sobre un fondo del color
/// identificador del cliente con 13% de opacidad (equivalente a `+ '22'`
/// en hex del prototipo original).
class AppAvatar extends StatelessWidget {
  final Client client;
  final double size;

  const AppAvatar({super.key, required this.client, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = Color(client.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        Formatters.initials(client.name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
