import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/auth_providers/login_provider.dart';
import 'package:studypro/providers/feed_back_provider.dart';
import 'package:studypro/providers/userProfileProvider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isEditingProfile = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Uri _url = Uri.parse('https://www.linkedin.com/in/ghazanfar-ali-leghari/');

  Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
      if (FirebaseAuth.instance.currentUser != null) {
        userProvider.loadCachedPhoto();
        userProvider.fetchUserProfile();
        if (userProvider.profilePhotoUrl == null) {
          userProvider.fetchProfilePhoto();
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _countryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar('Please log in to upload a profile photo', isError: true);
      return;
    }

    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    
    if (image != null) {
      await userProvider.uploadProfilePhoto(image);
      if (userProvider.error != null) {
        _showSnackBar(userProvider.error!, isError: true);
      } else {
        _showSnackBar('Profile photo updated successfully!');
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

  void _toggleEditProfile() {
    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (_isEditingProfile) {
        _usernameController.text = userProvider.username ?? '';
        _countryController.text = userProvider.country ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);

    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('Username cannot be empty', isError: true);
      return;
    }

    await userProvider.updateUserProfile(
      username: _usernameController.text.trim(),
      country: _countryController.text.trim(),
    );

    if (userProvider.error != null) {
      _showSnackBar(userProvider.error!, isError: true);
    } else {
      _showSnackBar('Profile updated successfully!');
      setState(() {
        _isEditingProfile = false;
      });
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => const FeedbackDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
           fontWeight: FontWeight.w600, color: Colors.white,fontSize: 24
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration:  BoxDecoration(
           gradient:  LinearGradient(
  colors: themeProvider.isDarkMode
      ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)]
      : [Colors.blue, const Color.fromARGB(255, 36, 36, 36)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
),
          ),
        ),
      
      ),
      body: Consumer3<UserProfileProvider, LoginProvider, ThemeProvider>(
        builder: (context, userProvider, loginProvider, themeProvider, child) {
          final currentUser = FirebaseAuth.instance.currentUser;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
              child: Column(
                children: [

                  _buildCardProfileSection(userProvider, currentUser, loginProvider, isTablet),

                   SizedBox(height: SizeConfig().scaleHeight(24, context),),

                  _buildSettingsSection('Account', [
                    _buildProfileEditTile(),
                    _buildAccountInfoTile(currentUser, loginProvider),
                  ]),

                   SizedBox(height: SizeConfig().scaleHeight(16, context),),

                  _buildSettingsSection('Preferences', [
                    _buildThemeTile(themeProvider),
                    
                  ]),

                   SizedBox(height: SizeConfig().scaleHeight(16, context),),

                  _buildSettingsSection('Progress', [
                    _buildStreakInfoTile(userProvider),
                 
                  ]),

                  const SizedBox(height: 16),

                  _buildSettingsSection('Support', [
                    _buildFeedbackTile(),
                    _buildHelpTile(),
                  ]),

                   SizedBox(height: SizeConfig().scaleHeight(24, context),),

                  _buildEnhancedLogoutButton(loginProvider, userProvider),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildCardProfileSection(
  UserProfileProvider userProvider,
  User? currentUser,
  LoginProvider loginProvider,
  bool isTablet,
) {

  return Container(
    width: double.infinity,
    constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
    margin: const EdgeInsets.symmetric(horizontal: 0),
    decoration: BoxDecoration(
      color: AppColors.cardBackground(context),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow(context),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 24, 30),
      child: _isEditingProfile
          ? _buildEditProfileCard(userProvider)
          : _buildProfileDisplayCard(userProvider, currentUser, loginProvider),
    ),
  );
}
Widget _buildProfileDisplayCard(
 
  UserProfileProvider userProvider,
  User? currentUser,
  LoginProvider loginProvider,
) {
   final themeProvider = Provider.of<ThemeProvider>(context);
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildCardProfilePhoto(userProvider),
       SizedBox(width: SizeConfig().scaleWidth(20, context),),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             SizedBox(height: SizeConfig().scaleHeight(8, context),),
            Text(
              userProvider.username ?? 'Anonymous User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? const Color.fromARGB(255, 51, 52, 54) : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromARGB(255, 179, 181, 184).withOpacity(0.1),
                  
                ),
              ),
              child: Text(
                loginProvider.userRole ?? 'Student',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDarkMode ? AppColors.primaryLight: const Color.fromARGB(255, 95, 105, 139),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildEditProfileCard(UserProfileProvider userProvider) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCardProfilePhoto(userProvider),
         SizedBox(width: SizeConfig().scaleWidth(20, context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
               SizedBox(height: SizeConfig().scaleHeight(20, context),),
              _buildStyledTextField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.person_outline,
              ),
               SizedBox(height: SizeConfig().scaleHeight(16, context),),
              _buildStyledTextField(
                controller: _countryController,
                label: 'Country',
                icon: Icons.location_on_outlined,
              ),
               SizedBox(height: SizeConfig().scaleHeight(20, context),),
              Column(
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditingProfile = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                       SizedBox(width: SizeConfig().scaleWidth(8, context)),
                      ElevatedButton(
                        
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Text('Save Changes',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w600),)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildCardProfilePhoto(UserProfileProvider userProvider) {
  return Stack(
    children: [
      GestureDetector(
        onTap: _pickAndUploadImage,
        child: Container(
          width: SizeConfig().scaleWidth(100, context),
          height: SizeConfig().scaleHeight(100, context),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border(context),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: userProvider.isLoading
                ? Container(
                    color: AppColors.background(context).withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : userProvider.profilePhotoUrl != null
                    ? Image.network(
                        userProvider.profilePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.background(context).withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.iconSecondary(context),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.background(context).withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.iconSecondary(context),
                        ),
                      ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: SizeConfig().scaleWidth(28, context),
          height: SizeConfig().scaleHeight(24, context),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    ],
  );
}

Widget _buildStyledTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.iconPrimary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: AppColors.background(context).withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference < 30) {
      return '$difference days ago';
    } else if (difference < 365) {
      return '${(difference / 30).floor()} months ago';
    } else {
      return '${(difference / 365).floor()} years ago';
    }
  }

Widget _buildSettingsSection(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    ],
  );
}

  Widget _buildProfileEditTile() {
    final themeProvider = Provider.of<ThemeProvider>(context); 
    return _buildEnhancedListTile(
      icon: _isEditingProfile ? Icons.save : Icons.edit,
      title: _isEditingProfile ? 'Save Profile' : 'Edit Profile',
      subtitle: _isEditingProfile ? 'Save your changes' : 'Update your information',
      onTap: _isEditingProfile ? _saveProfile : _toggleEditProfile,
      iconColor: themeProvider.isDarkMode ? AppColors.primaryLight: AppColors.primary,
    );
  }

  Widget _buildAccountInfoTile(User? currentUser, LoginProvider loginProvider) {
    return _buildEnhancedListTile(
      icon: Icons.account_circle,
      title: 'Account Info',
      subtitle: 'Joined ${_formatJoinDate(currentUser?.metadata.creationTime)}',
      onTap: () {
  
      },
      iconColor: Colors.blue,
    );
  }

 Widget _buildThemeTile(ThemeProvider themeProvider) {
  return _buildEnhancedListTile(
    icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
    title: 'Appearance',
    subtitle: themeProvider.isDarkMode ? 'Dark mode' : 'Light mode',
    trailing: Transform.scale(
      scale: 0.8,
      child: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(value),
        activeColor: AppColors.primary,
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border(context);
        }),
      ),
    ),
    iconColor: themeProvider.isDarkMode ? AppColors.warning : AppColors.primary,
  );
}  


Widget _buildStreakInfoTile(UserProfileProvider userProvider) {
  return _buildEnhancedListTile(
    icon: Icons.local_fire_department,
    title: 'Learning Streak',
    subtitle: 'Current: ${userProvider.learningStreak ?? 0} days • '
            'Best: ${userProvider.longestStreak ?? 0} days',
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🔥 ${userProvider.learningStreak ?? 0}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.warning,
        ),
      ),
    ),
    iconColor: AppColors.warning,
  );
}



  Widget _buildFeedbackTile() {
    return _buildEnhancedListTile(
      icon: Icons.feedback,
      title: 'Send Feedback',
      subtitle: 'Help us improve the app',
      onTap: _showFeedbackDialog,
      iconColor: Colors.teal,
    );
  }

  Widget _buildHelpTile() {
    return _buildEnhancedListTile(
      icon: Icons.help_outline,
      title: 'Help & Support',
      subtitle: 'FAQs and contact support',
      onTap:_launchUrl,
      iconColor: Colors.indigo,
    );
  }

 Widget _buildEnhancedListTile({
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
  Widget? trailing,
  Color? iconColor,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.iconPrimary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.textPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconSecondary(context)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

  Widget _buildEnhancedLogoutButton(LoginProvider loginProvider, UserProfileProvider userProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await _showLogoutConfirmation();
          if (confirmed == true) {
            await loginProvider.logout(context);
            await userProvider.clearCachedPhoto();
          }
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackController = TextEditingController();
  String _selectedType = 'General';
  int _rating = 5;
  final List<String> _feedbackTypes = ['General', 'Bug Report', 'Feature Request', 'Improvement'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackProvider>(
      builder: (context, feedbackProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardBackground(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.feedback, color: AppColors.primary),
                    ),
                     SizedBox(width: SizeConfig().scaleWidth(12, context)),
                    Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: SizeConfig().scaleHeight(24, context),),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rate your experience',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context),),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      child: Icon(
                        Icons.star,
                        color: index < _rating ? AppColors.warning : AppColors.border(context),
                        size: 30,
                      ),
                    );
                  }),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(20, context),),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Feedback Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    filled: true,
                    fillColor: AppColors.background(context).withOpacity(0.05),
                  ),
                  items: _feedbackTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type, style: TextStyle(color: AppColors.textPrimary(context))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context),),
                TextField(
                  controller: _feedbackController,
                  decoration: InputDecoration(
                    labelText: 'Your Feedback',
                    hintText: 'Tell us what you think...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    filled: true,
                    fillColor: AppColors.background(context).withOpacity(0.05),
                  ),
                  maxLines: 4,
                ),
                 SizedBox(height: SizeConfig().scaleHeight(24, context),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textPrimary(context))),
                    ),
                     SizedBox(width: SizeConfig().scaleWidth(12, context)),
                    ElevatedButton(
  onPressed: (feedbackProvider.isSubmitting)
      ? null
      : () async {
          if (_feedbackController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please enter your feedback', style: TextStyle(color: Colors.white)),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          await feedbackProvider.submitFeedback(
            type: _selectedType,
            message: _feedbackController.text.trim(),
          );
          if (mounted) {
            if (feedbackProvider.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(feedbackProvider.error!, style: TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.error,
                ),
              );
            } else {
              await feedbackProvider.getUserFeedback();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: SizeConfig().scaleWidth(8, context)),
                      Text('Feedback submitted successfully!', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: feedbackProvider.isSubmitting
      ?  SizedBox(
          width: SizeConfig().scaleWidth(20, context),
          height: SizeConfig().scaleHeight(20, context),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : const Text(
          'Submit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}