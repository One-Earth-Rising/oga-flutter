import 'package:flutter/material.dart';
import 'package:oga_web_showcase/screens/oga_account_dashboard_main.dart';
import 'package:oga_web_showcase/screens/fbs_campaign_dashboard.dart';

class DashboardWrapper extends StatelessWidget {
  final String? campaignId;

  const DashboardWrapper({super.key, this.campaignId});

  @override
  Widget build(BuildContext context) {
    // If the user came from the FBS campaign, show the FBS dashboard
    if (campaignId == 'fbs_launch') {
      return const FBSCampaignDashboard();
    }

    // Default to the standard dashboard
    return const OGAAccountDashboard();
  }
}
