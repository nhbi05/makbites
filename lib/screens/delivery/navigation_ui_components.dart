import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_location.dart';
import '../../services/navigation_service.dart';
import '../../services/location_service.dart';

// Navigation panel widget
class NavigationPanel extends StatelessWidget {
  final DeliveryLocation destination;
  final VoidCallback? onStopNavigation;
  final VoidCallback? onLaunchExternal;
  
  const NavigationPanel({
    Key? key,
    required this.destination,
    this.onStopNavigation,
    this.onLaunchExternal,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        NavigationSummary summary = navigationService.getNavigationSummary();
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Navigating to ${destination.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onStopNavigation,
                    ),
                  ],
                ),
              ),
              
              // Current step
              if (summary.currentStep != null)
                _buildCurrentStepCard(summary.currentStep!),
              
              // Progress and ETA
              _buildProgressSection(summary),
              
              // Action buttons
              _buildActionButtons(context, navigationService),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCurrentStepCard(NavigationStep step) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Maneuver icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                step.maneuverIcon,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Instruction and distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.cleanInstruction,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'in ${step.formattedDistance}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressSection(NavigationSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                'Step ${summary.currentStepIndex + 1} of ${summary.totalSteps}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '${summary.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: summary.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 12),
          
          // ETA and distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'ETA',
                value: _formatDuration(summary.estimatedTimeToArrival),
              ),
              _buildInfoItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${summary.remainingDistance.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context, NavigationService navigationService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.launch),
              label: const Text('External Maps'),
              onPressed: onLaunchExternal,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              onPressed: onStopNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

// Compact navigation bar for bottom of screen
class CompactNavigationBar extends StatelessWidget {
  final DeliveryLocation destination;
  final VoidCallback? onTap;
  
  const CompactNavigationBar({
    Key? key,
    required this.destination,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        NavigationSummary summary = navigationService.getNavigationSummary();
        
        if (!summary.isNavigating) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Maneuver icon
                if (summary.currentStep != null)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        summary.currentStep!.maneuverIcon,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                
                // Instruction
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.currentStep?.cleanInstruction ?? 'Navigate to ${destination.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.remainingDistance.toStringAsFixed(1)} km • ${_formatDuration(summary.estimatedTimeToArrival)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Expand icon
                Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

// Navigation step list widget
class NavigationStepsList extends StatelessWidget {
  const NavigationStepsList({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        List<NavigationStep> steps = navigationService.currentSteps;
        int currentIndex = navigationService.currentStepIndex;
        
        if (steps.isEmpty) {
          return const Center(
            child: Text('No navigation steps available'),
          );
        }
        
        return ListView.builder(
          itemCount: steps.length,
          itemBuilder: (context, index) {
            NavigationStep step = steps[index];
            bool isCurrent = index == currentIndex;
            bool isCompleted = index < currentIndex;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent 
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent 
                    ? Border.all(color: const Color(0xFF2196F3), width: 2)
                    : null,
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green
                        : isCurrent 
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            step.maneuverIcon,
                            style: TextStyle(
                              fontSize: 16,
                              color: isCurrent ? Colors.white : Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                title: Text(
                  step.cleanInstruction,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                subtitle: Text(
                  '${step.formattedDistance} • ${step.formattedDuration}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: isCurrent 
                    ? const Icon(Icons.navigation, color: Color(0xFF2196F3))
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// Navigation floating action button
class NavigationFAB extends StatelessWidget {
  final DeliveryLocation destination;
  final VoidCallback? onPressed;
  
  const NavigationFAB({
    Key? key,
    required this.destination,
    this.onPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        bool isNavigating = navigationService.isNavigating;
        
        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: isNavigating ? Colors.red : const Color(0xFF2196F3),
          icon: Icon(
            isNavigating ? Icons.stop : Icons.navigation,
            color: Colors.white,
          ),
          label: Text(
            isNavigating ? 'Stop Navigation' : 'Start Navigation',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}

// Voice instruction widget (for future implementation)
class VoiceInstructionWidget extends StatelessWidget {
  const VoiceInstructionWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        NavigationStep? currentStep = navigationService.currentStep;
        
        if (currentStep == null || !navigationService.isNavigating) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentStep.cleanInstruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.replay, color: Colors.white),
                onPressed: () {
                  // TODO: Implement text-to-speech replay
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

