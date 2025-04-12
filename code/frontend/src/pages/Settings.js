import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Grid,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';

const Settings = () => {
  const [settings, setSettings] = useState({
    email: 'user@example.com',
    notifications: true,
    darkMode: false,
    language: 'English',
    timezone: 'UTC',
  });

  const [saveStatus, setSaveStatus] = useState(null);

  const handleChange = (field) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setSettings((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSave = () => {
    // Simulate saving settings
    setSaveStatus('success');
    setTimeout(() => setSaveStatus(null), 3000);
  };

  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      <Typography variant="h4" gutterBottom>
        Settings
      </Typography>

      {saveStatus && (
        <Alert severity={saveStatus} sx={{ mb: 3 }}>
          Settings saved successfully!
        </Alert>
      )}

      <Paper sx={{ p: 3 }}>
        <Grid container spacing={3}>
          {/* Account Settings */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom>
              Account Settings
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Email"
                  value={settings.email}
                  onChange={handleChange('email')}
                />
              </Grid>
            </Grid>
          </Grid>

          <Grid item xs={12}>
            <Divider />
          </Grid>

          {/* Preferences */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom>
              Preferences
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifications}
                      onChange={handleChange('notifications')}
                    />
                  }
                  label="Enable Notifications"
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.darkMode}
                      onChange={handleChange('darkMode')}
                    />
                  }
                  label="Dark Mode"
                />
              </Grid>
            </Grid>
          </Grid>

          <Grid item xs={12}>
            <Divider />
          </Grid>

          {/* Regional Settings */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom>
              Regional Settings
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  select
                  label="Language"
                  value={settings.language}
                  onChange={handleChange('language')}
                  SelectProps={{
                    native: true,
                  }}
                >
                  <option value="English">English</option>
                  <option value="Spanish">Spanish</option>
                  <option value="French">French</option>
                </TextField>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  select
                  label="Timezone"
                  value={settings.timezone}
                  onChange={handleChange('timezone')}
                  SelectProps={{
                    native: true,
                  }}
                >
                  <option value="UTC">UTC</option>
                  <option value="EST">EST</option>
                  <option value="PST">PST</option>
                </TextField>
              </Grid>
            </Grid>
          </Grid>

          {/* Save Button */}
          <Grid item xs={12}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="contained"
                startIcon={<SaveIcon />}
                onClick={handleSave}
              >
                Save Changes
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>
    </Container>
  );
};

export default Settings; 