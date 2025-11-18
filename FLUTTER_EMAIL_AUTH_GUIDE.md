# Flutter Email Authentication Update Guide

## ✅ BACKEND COMPLETE - Deployed to GitHub

Backend changes have been committed and pushed. Render will automatically redeploy.

**Important**: After deployment, add these environment variables in Render Dashboard:

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password
OTP_EXPIRY_MINUTES=5
STATIC_OTP=100623
```

## 📱 FLUTTER CHANGES REQUIRED

### Summary of What Needs to Change

The backend now expects:
- **Signup**: `email`, `age`, `name`, `state` (mobile is optional)
- **Login**: `email` (instead of mobile)
- **OTP Verify**: `email`, `otp` (instead of mobile, otp)

### Files That Need Updates

#### 1. ✅ User Model - ALREADY UPDATED
- `lib/models/user.dart` ✅ Complete

#### 2. Auth Provider/BLoC Files
- `lib/providers/auth_event.dart`
- `lib/providers/auth_bloc.dart`
- `lib/providers/auth_state.dart`

#### 3. Auth Service
- `lib/core/api/auth_api_service.dart` (or similar)

#### 4. Signup Screen
- `lib/features/auth/screens/signup_screen.dart`

#### 5. Login Screen
- `lib/features/auth/screens/login_screen.dart`

---

## STEP-BY-STEP FLUTTER UPDATES

### Step 1: Update Auth Events

File: `lib/providers/auth_event.dart`

Find `AuthRegisterRequested` and update:

```dart
// OLD
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String mobile;
  final String state;
  
  AuthRegisterRequested({
    required this.name,
    required this.mobile,
    required this.state,
  });
}

// NEW
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final int age;
  final String state;
  
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.age,
    required this.state,
  });
}
```

Find `AuthSendOtpRequested` and update:

```dart
// OLD
class AuthSendOtpRequested extends AuthEvent {
  final String mobile;
  
  AuthSendOtpRequested({required this.mobile});
}

// NEW
class AuthSendOtpRequested extends AuthEvent {
  final String email;
  
  AuthSendOtpRequested({required this.email});
}
```

Find `AuthOtpVerifyRequested` and update:

```dart
// OLD
class AuthOtpVerifyRequested extends AuthEvent {
  final String mobile;
  final String otp;
  
  AuthOtpVerifyRequested({
    required this.mobile,
    required this.otp,
  });
}

// NEW
class AuthOtpVerifyRequested extends AuthEvent {
  final String email;
  final String otp;
  
  AuthOtpVerifyRequested({
    required this.email,
    required this.otp,
  });
}
```

### Step 2: Update Auth Service/Repository

File: `lib/core/api/auth_api_service.dart` (or wherever your API calls are)

Update the register method:

```dart
// OLD
Future<Map<String, dynamic>> register({
  required String name,
  required String mobile,
  required String state,
}) async {
  final response = await dio.post('/auth/register', data: {
    'name': name,
    'mobile': mobile,
    'state': state,
  });
  return response.data;
}

// NEW
Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required int age,
  required String state,
}) async {
  final response = await dio.post('/auth/register', data: {
    'name': name,
    'email': email,
    'age': age,
    'state': state,
  });
  return response.data;
}
```

Update sendOtp method:

```dart
// OLD
Future<Map<String, dynamic>> sendOtp(String mobile) async {
  final response = await dio.post('/auth/send-otp', data: {
    'mobile': mobile,
  });
  return response.data;
}

// NEW
Future<Map<String, dynamic>> sendOtp(String email) async {
  final response = await dio.post('/auth/send-otp', data: {
    'email': email,
  });
  return response.data;
}
```

Update verifyOtp method:

```dart
// OLD
Future<Map<String, dynamic>> verifyOtp({
  required String mobile,
  required String otp,
}) async {
  final response = await dio.post('/auth/verify-otp', data: {
    'mobile': mobile,
    'otp': otp,
  });
  return response.data;
}

// NEW
Future<Map<String, dynamic>> verifyOtp({
  required String email,
  required String otp,
}) async {
  final response = await dio.post('/auth/verify-otp', data: {
    'email': email,
    'otp': otp,
  });
  return response.data;
}
```

### Step 3: Update Signup Screen UI

File: `lib/features/auth/screens/signup_screen.dart`

Add new controllers:

```dart
// Add these controllers
final TextEditingController _emailController = TextEditingController();
final TextEditingController _ageController = TextEditingController();

// Keep existing controllers
final TextEditingController _nameController = TextEditingController();
final TextEditingController _stateController = TextEditingController();
final TextEditingController _otpController = TextEditingController();
```

Add email TextField (replace mobile TextField):

```dart
_buildTextField(
  controller: _emailController,
  labelText: 'Email Address',
  hintText: 'Enter your email',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  },
),
```

Add age TextField:

```dart
_buildTextField(
  controller: _ageController,
  labelText: 'Age',
  hintText: 'Enter your age',
  prefixIcon: Icons.cake_outlined,
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null || age < 13 || age > 120) {
      return 'Age must be between 13 and 120';
    }
    return null;
  },
),
```

Update _sendOtp() method:

```dart
void _sendOtp() async {
  if (_emailController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      _ageController.text.trim().isNotEmpty &&
      _selectedState != null &&
      _selectedState!.isNotEmpty) {
    setState(() {
      _isLoading = true;
    });

    // Validate age
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 13 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age (13-120)')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: age,
        state: _selectedState!,
      ),
    );
  }
}
```

Update _submit() method:

```dart
void _submit() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() {
      _isLoading = true;
    });

    context.read<AuthBloc>().add(
      AuthOtpVerifyRequested(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      ),
    );
  }
}
```

Don't forget to dispose new controllers:

```dart
@override
void dispose() {
  _animationController.dispose();
  _nameController.dispose();
  _emailController.dispose();
  _ageController.dispose();
  _stateController.dispose();
  _otpController.dispose();
  super.dispose();
}
```

### Step 4: Update Login Screen UI

File: `lib/features/auth/screens/login_screen.dart`

Replace mobile TextField with email TextField:

```dart
// OLD
_buildTextField(
  controller: _mobileController,
  labelText: 'Mobile Number',
  hintText: 'Enter your 10-digit mobile number',
  prefixIcon: Icons.phone_outlined,
  keyboardType: TextInputType.phone,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  },
),

// NEW
_buildTextField(
  controller: _emailController,
  labelText: 'Email Address',
  hintText: 'Enter your email',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  },
),
```

Rename controller:

```dart
// Change from
final TextEditingController _mobileController = TextEditingController();

// To
final TextEditingController _emailController = TextEditingController();
```

Update _sendOtp() method:

```dart
void _sendOtp() async {
  if (_emailController.text.trim().isNotEmpty) {
    setState(() {
      _isLoading = true;
    });

    context.read<AuthBloc>().add(
      AuthSendOtpRequested(
        email: _emailController.text.trim(),
      ),
    );
  }
}
```

Update _submit() method:

```dart
void _submit() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() {
      _isLoading = true;
    });

    context.read<AuthBloc>().add(
      AuthOtpVerifyRequested(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      ),
    );
  }
}
```

Update success message to show email:

```dart
Text(
  'OTP sent to ${_emailController.text}',
  style: TextStyle(color: Colors.grey),
),
```

### Step 5: Update Auth BLoC Handler

File: `lib/providers/auth_bloc.dart`

Update the register handler:

```dart
// Find the handler for AuthRegisterRequested
on<AuthRegisterRequested>((event, emit) async {
  try {
    emit(AuthLoading());
    
    final response = await _authService.register(
      name: event.name,
      email: event.email,
      age: event.age,
      state: event.state,
    );
    
    emit(AuthOtpSent(
      userId: response['data']['userId'],
      email: event.email,
    ));
  } catch (e) {
    emit(AuthError(e.toString()));
  }
});
```

Update sendOtp handler:

```dart
on<AuthSendOtpRequested>((event, emit) async {
  try {
    emit(AuthLoading());
    
    final response = await _authService.sendOtp(event.email);
    
    emit(AuthOtpSent(
      userId: response['data']['userId'],
      email: event.email,
    ));
  } catch (e) {
    emit(AuthError(e.toString()));
  }
});
```

Update verifyOtp handler:

```dart
on<AuthOtpVerifyRequested>((event, emit) async {
  try {
    emit(AuthLoading());
    
    final response = await _authService.verifyOtp(
      email: event.email,
      otp: event.otp,
    );
    
    // Save token and user
    final token = response['data']['token'];
    final user = User.fromJson(response['data']['user']);
    
    await _saveAuthData(token, user);
    
    emit(AuthAuthenticated(user: user, token: token));
  } catch (e) {
    emit(AuthError(e.toString()));
  }
});
```

Update AuthOtpSent state (if exists):

```dart
// OLD
class AuthOtpSent extends AuthState {
  final String userId;
  final String mobile;
  
  AuthOtpSent({required this.userId, required this.mobile});
}

// NEW
class AuthOtpSent extends AuthState {
  final String userId;
  final String email;
  
  AuthOtpSent({required this.userId, required this.email});
}
```

---

## Testing Checklist

After making all changes:

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Signup Flow**:
   - Enter name, email, age, state
   - Click "Send OTP"
   - Check email for OTP (or use 100623)
   - Enter OTP
   - Verify successful registration

3. **Test Login Flow**:
   - Enter email
   - Click "Send OTP"
   - Check email for OTP (or use 100623)
   - Enter OTP
   - Verify successful login

4. **Test Validation**:
   - Try invalid email format
   - Try age < 13
   - Try age > 120
   - Verify error messages show

---

## Common Issues & Solutions

### Issue: "Email already exists"
- Solution: Use a different email or delete existing user from database

### Issue: OTP not received
- Check SMTP credentials in Render dashboard
- Check spam/junk folder
- Use static OTP: 100623 for testing

### Issue: API returns 400
- Check console logs for validation errors
- Verify all required fields are sent
- Check email format is valid

### Issue: User.mobile errors
- Update any code that references user.mobile
- Make it optional: user.mobile?

---

## Next Steps After Flutter Updates

1. Test locally with backend running
2. Build APK: `flutter build apk`
3. Test on real device
4. Update any other screens that display user info
5. Update profile screen if it shows mobile
6. Search codebase for "mobile" references and update

---

## Backend is Ready! ✅

The backend has been deployed with email authentication. Once you update Flutter:
- Signup will create users with email and age
- Login will use email instead of mobile
- OTP will be sent via email
- All existing functionality remains the same

Good luck with the Flutter updates! 🚀
