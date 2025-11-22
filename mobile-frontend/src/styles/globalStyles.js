import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
    palette: {
        mode: 'light',
        primary: {
            main: '#3a36e0',
            light: '#6e6fe6',
            dark: '#2a26a0',
            contrastText: '#ffffff',
        },
        secondary: {
            main: '#6c63ff',
            light: '#9d97ff',
            dark: '#4b44b3',
            contrastText: '#ffffff',
        },
        background: {
            default: '#f8f9fc',
            paper: '#ffffff',
        },
        error: {
            main: '#f44336',
            light: '#e57373',
            dark: '#d32f2f',
        },
        warning: {
            main: '#ff9800',
            light: '#ffb74d',
            dark: '#f57c00',
        },
        info: {
            main: '#03a9f4',
            light: '#4fc3f7',
            dark: '#0288d1',
        },
        success: {
            main: '#4caf50',
            light: '#81c784',
            dark: '#388e3c',
        },
        text: {
            primary: '#2d3748',
            secondary: '#718096',
            disabled: '#a0aec0',
        },
        divider: 'rgba(0, 0, 0, 0.08)',
    },
    typography: {
        fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
        h1: {
            fontSize: '2.5rem',
            fontWeight: 700,
            lineHeight: 1.2,
            letterSpacing: '-0.01562em',
        },
        h2: {
            fontSize: '2rem',
            fontWeight: 700,
            lineHeight: 1.2,
            letterSpacing: '-0.00833em',
        },
        h3: {
            fontSize: '1.75rem',
            fontWeight: 600,
            lineHeight: 1.2,
            letterSpacing: '0em',
        },
        h4: {
            fontSize: '1.5rem',
            fontWeight: 600,
            lineHeight: 1.2,
            letterSpacing: '0.00735em',
        },
        h5: {
            fontSize: '1.25rem',
            fontWeight: 600,
            lineHeight: 1.2,
            letterSpacing: '0em',
        },
        h6: {
            fontSize: '1rem',
            fontWeight: 600,
            lineHeight: 1.2,
            letterSpacing: '0.0075em',
        },
        subtitle1: {
            fontSize: '1rem',
            fontWeight: 500,
            lineHeight: 1.5,
            letterSpacing: '0.00938em',
        },
        subtitle2: {
            fontSize: '0.875rem',
            fontWeight: 500,
            lineHeight: 1.5,
            letterSpacing: '0.00714em',
        },
        body1: {
            fontSize: '1rem',
            fontWeight: 400,
            lineHeight: 1.5,
            letterSpacing: '0.00938em',
        },
        body2: {
            fontSize: '0.875rem',
            fontWeight: 400,
            lineHeight: 1.5,
            letterSpacing: '0.01071em',
        },
        button: {
            fontSize: '0.875rem',
            fontWeight: 600,
            lineHeight: 1.75,
            letterSpacing: '0.02857em',
            textTransform: 'none',
        },
        caption: {
            fontSize: '0.75rem',
            fontWeight: 400,
            lineHeight: 1.66,
            letterSpacing: '0.03333em',
        },
        overline: {
            fontSize: '0.75rem',
            fontWeight: 600,
            lineHeight: 2.66,
            letterSpacing: '0.08333em',
            textTransform: 'uppercase',
        },
    },
    shape: {
        borderRadius: 12,
    },
    shadows: [
        'none',
        '0px 2px 1px -1px rgba(0,0,0,0.05),0px 1px 1px 0px rgba(0,0,0,0.03),0px 1px 3px 0px rgba(0,0,0,0.05)',
        '0px 3px 3px -2px rgba(0,0,0,0.05),0px 2px 6px 0px rgba(0,0,0,0.03),0px 1px 8px 0px rgba(0,0,0,0.05)',
        '0px 3px 4px -2px rgba(0,0,0,0.05),0px 3px 8px 0px rgba(0,0,0,0.03),0px 1px 12px 0px rgba(0,0,0,0.05)',
        '0px 4px 5px -2px rgba(0,0,0,0.05),0px 4px 10px 0px rgba(0,0,0,0.03),0px 1px 16px 0px rgba(0,0,0,0.05)',
        '0px 5px 8px -3px rgba(0,0,0,0.05),0px 5px 12px 0px rgba(0,0,0,0.03),0px 3px 16px 0px rgba(0,0,0,0.05)',
        '0px 6px 10px -4px rgba(0,0,0,0.05),0px 7px 14px 0px rgba(0,0,0,0.03),0px 4px 18px 0px rgba(0,0,0,0.05)',
        '0px 7px 10px -4px rgba(0,0,0,0.05),0px 8px 16px 0px rgba(0,0,0,0.03),0px 6px 20px 0px rgba(0,0,0,0.05)',
        '0px 8px 12px -5px rgba(0,0,0,0.05),0px 9px 18px 0px rgba(0,0,0,0.03),0px 7px 22px 0px rgba(0,0,0,0.05)',
        '0px 9px 14px -6px rgba(0,0,0,0.05),0px 10px 20px 0px rgba(0,0,0,0.03),0px 8px 24px 0px rgba(0,0,0,0.05)',
        '0px 10px 16px -7px rgba(0,0,0,0.05),0px 11px 22px 0px rgba(0,0,0,0.03),0px 9px 26px 0px rgba(0,0,0,0.05)',
        '0px 11px 18px -8px rgba(0,0,0,0.05),0px 12px 24px 0px rgba(0,0,0,0.03),0px 10px 28px 0px rgba(0,0,0,0.05)',
        '0px 12px 20px -9px rgba(0,0,0,0.05),0px 13px 26px 0px rgba(0,0,0,0.03),0px 11px 30px 0px rgba(0,0,0,0.05)',
        '0px 13px 22px -10px rgba(0,0,0,0.05),0px 14px 28px 0px rgba(0,0,0,0.03),0px 12px 32px 0px rgba(0,0,0,0.05)',
        '0px 14px 24px -11px rgba(0,0,0,0.05),0px 15px 30px 0px rgba(0,0,0,0.03),0px 13px 34px 0px rgba(0,0,0,0.05)',
        '0px 15px 26px -12px rgba(0,0,0,0.05),0px 16px 32px 0px rgba(0,0,0,0.03),0px 14px 36px 0px rgba(0,0,0,0.05)',
        '0px 16px 28px -13px rgba(0,0,0,0.05),0px 17px 34px 0px rgba(0,0,0,0.03),0px 15px 38px 0px rgba(0,0,0,0.05)',
        '0px 17px 30px -14px rgba(0,0,0,0.05),0px 18px 36px 0px rgba(0,0,0,0.03),0px 16px 40px 0px rgba(0,0,0,0.05)',
        '0px 18px 32px -15px rgba(0,0,0,0.05),0px 19px 38px 0px rgba(0,0,0,0.03),0px 17px 42px 0px rgba(0,0,0,0.05)',
        '0px 19px 34px -16px rgba(0,0,0,0.05),0px 20px 40px 0px rgba(0,0,0,0.03),0px 18px 44px 0px rgba(0,0,0,0.05)',
        '0px 20px 36px -17px rgba(0,0,0,0.05),0px 21px 42px 0px rgba(0,0,0,0.03),0px 19px 46px 0px rgba(0,0,0,0.05)',
        '0px 21px 38px -18px rgba(0,0,0,0.05),0px 22px 44px 0px rgba(0,0,0,0.03),0px 20px 48px 0px rgba(0,0,0,0.05)',
        '0px 22px 40px -19px rgba(0,0,0,0.05),0px 23px 46px 0px rgba(0,0,0,0.03),0px 21px 50px 0px rgba(0,0,0,0.05)',
        '0px 23px 42px -20px rgba(0,0,0,0.05),0px 24px 48px 0px rgba(0,0,0,0.03),0px 22px 52px 0px rgba(0,0,0,0.05)',
    ],
    components: {
        MuiCssBaseline: {
            styleOverrides: {
                '@font-face': {
                    fontFamily: 'Inter',
                    fontStyle: 'normal',
                    fontDisplay: 'swap',
                    fontWeight: 400,
                    src: `url(https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap)`,
                },
            },
        },
        MuiButton: {
            styleOverrides: {
                root: {
                    textTransform: 'none',
                    borderRadius: 12,
                    padding: '10px 20px',
                    boxShadow: 'none',
                    '&:hover': {
                        boxShadow: '0 4px 12px rgba(58, 54, 224, 0.15)',
                    },
                },
                contained: {
                    '&:hover': {
                        boxShadow: '0 8px 16px rgba(58, 54, 224, 0.2)',
                    },
                },
                containedPrimary: {
                    background: 'linear-gradient(45deg, #3a36e0 0%, #6c63ff 100%)',
                    '&:hover': {
                        background: 'linear-gradient(45deg, #2a26a0 0%, #4b44b3 100%)',
                    },
                },
                outlined: {
                    borderWidth: '2px',
                    '&:hover': {
                        borderWidth: '2px',
                    },
                },
            },
        },
        MuiCard: {
            styleOverrides: {
                root: {
                    borderRadius: 16,
                    boxShadow: '0 4px 20px rgba(0, 0, 0, 0.05)',
                    overflow: 'hidden',
                    transition: 'transform 0.3s ease-in-out, box-shadow 0.3s ease-in-out',
                    '&:hover': {
                        transform: 'translateY(-5px)',
                        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.08)',
                    },
                },
            },
        },
        MuiCardContent: {
            styleOverrides: {
                root: {
                    padding: '24px',
                    '&:last-child': {
                        paddingBottom: '24px',
                    },
                },
            },
        },
        MuiCardHeader: {
            styleOverrides: {
                root: {
                    padding: '20px 24px',
                },
            },
        },
        MuiChip: {
            styleOverrides: {
                root: {
                    borderRadius: 8,
                    fontWeight: 500,
                },
            },
        },
        MuiPaper: {
            styleOverrides: {
                root: {
                    borderRadius: 16,
                },
                elevation1: {
                    boxShadow: '0 2px 12px rgba(0, 0, 0, 0.05)',
                },
            },
        },
        MuiTableCell: {
            styleOverrides: {
                root: {
                    borderBottom: '1px solid rgba(0, 0, 0, 0.05)',
                    padding: '16px 24px',
                },
                head: {
                    fontWeight: 600,
                    backgroundColor: 'rgba(0, 0, 0, 0.02)',
                },
            },
        },
        MuiTableRow: {
            styleOverrides: {
                root: {
                    '&:last-child td': {
                        borderBottom: 0,
                    },
                },
            },
        },
        MuiTextField: {
            styleOverrides: {
                root: {
                    '& .MuiOutlinedInput-root': {
                        borderRadius: 12,
                        '& fieldset': {
                            borderColor: 'rgba(0, 0, 0, 0.1)',
                        },
                        '&:hover fieldset': {
                            borderColor: 'rgba(58, 54, 224, 0.3)',
                        },
                        '&.Mui-focused fieldset': {
                            borderColor: '#3a36e0',
                        },
                    },
                },
            },
        },
        MuiTab: {
            styleOverrides: {
                root: {
                    textTransform: 'none',
                    fontWeight: 600,
                    fontSize: '0.875rem',
                },
            },
        },
        MuiTabs: {
            styleOverrides: {
                indicator: {
                    height: 3,
                    borderRadius: '3px 3px 0 0',
                },
            },
        },
        MuiListItem: {
            styleOverrides: {
                root: {
                    borderRadius: 8,
                    '&.Mui-selected': {
                        backgroundColor: 'rgba(58, 54, 224, 0.08)',
                        '&:hover': {
                            backgroundColor: 'rgba(58, 54, 224, 0.12)',
                        },
                    },
                },
            },
        },
        MuiListItemButton: {
            styleOverrides: {
                root: {
                    borderRadius: 8,
                    '&:hover': {
                        backgroundColor: 'rgba(0, 0, 0, 0.04)',
                    },
                },
            },
        },
        MuiAppBar: {
            styleOverrides: {
                root: {
                    boxShadow: '0 2px 10px rgba(0, 0, 0, 0.05)',
                },
            },
        },
        MuiDrawer: {
            styleOverrides: {
                paper: {
                    borderRight: '1px solid rgba(0, 0, 0, 0.05)',
                },
            },
        },
        MuiDivider: {
            styleOverrides: {
                root: {
                    borderColor: 'rgba(0, 0, 0, 0.05)',
                },
            },
        },
        MuiSwitch: {
            styleOverrides: {
                root: {
                    width: 42,
                    height: 26,
                    padding: 0,
                    '& .MuiSwitch-switchBase': {
                        padding: 0,
                        margin: 2,
                        transitionDuration: '300ms',
                        '&.Mui-checked': {
                            transform: 'translateX(16px)',
                            color: '#fff',
                            '& + .MuiSwitch-track': {
                                backgroundColor: '#3a36e0',
                                opacity: 1,
                                border: 0,
                            },
                        },
                    },
                    '& .MuiSwitch-thumb': {
                        boxSizing: 'border-box',
                        width: 22,
                        height: 22,
                    },
                    '& .MuiSwitch-track': {
                        borderRadius: 26 / 2,
                        backgroundColor: '#E9E9EA',
                        opacity: 1,
                    },
                },
            },
        },
    },
});

export const darkTheme = createTheme({
    ...theme,
    palette: {
        mode: 'dark',
        primary: {
            main: '#6c63ff',
            light: '#9d97ff',
            dark: '#4b44b3',
            contrastText: '#ffffff',
        },
        secondary: {
            main: '#3a36e0',
            light: '#6e6fe6',
            dark: '#2a26a0',
            contrastText: '#ffffff',
        },
        background: {
            default: '#121212',
            paper: '#1e1e1e',
        },
        text: {
            primary: '#ffffff',
            secondary: '#b0b0b0',
            disabled: '#6c6c6c',
        },
        divider: 'rgba(255, 255, 255, 0.08)',
    },
    components: {
        ...theme.components,
        MuiPaper: {
            styleOverrides: {
                root: {
                    borderRadius: 16,
                    backgroundImage: 'none',
                },
                elevation1: {
                    boxShadow: '0 2px 12px rgba(0, 0, 0, 0.2)',
                },
            },
        },
        MuiCard: {
            styleOverrides: {
                root: {
                    borderRadius: 16,
                    boxShadow: '0 4px 20px rgba(0, 0, 0, 0.2)',
                    backgroundImage: 'none',
                    transition: 'transform 0.3s ease-in-out, box-shadow 0.3s ease-in-out',
                    '&:hover': {
                        transform: 'translateY(-5px)',
                        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.3)',
                    },
                },
            },
        },
        MuiTableCell: {
            styleOverrides: {
                root: {
                    borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
                },
                head: {
                    backgroundColor: 'rgba(255, 255, 255, 0.05)',
                },
            },
        },
        MuiButton: {
            styleOverrides: {
                containedPrimary: {
                    background: 'linear-gradient(45deg, #6c63ff 0%, #3a36e0 100%)',
                    '&:hover': {
                        background: 'linear-gradient(45deg, #9d97ff 0%, #6e6fe6 100%)',
                    },
                },
            },
        },
        MuiTextField: {
            styleOverrides: {
                root: {
                    '& .MuiOutlinedInput-root': {
                        '& fieldset': {
                            borderColor: 'rgba(255, 255, 255, 0.15)',
                        },
                        '&:hover fieldset': {
                            borderColor: 'rgba(108, 99, 255, 0.3)',
                        },
                        '&.Mui-focused fieldset': {
                            borderColor: '#6c63ff',
                        },
                    },
                },
            },
        },
        MuiListItem: {
            styleOverrides: {
                root: {
                    '&.Mui-selected': {
                        backgroundColor: 'rgba(108, 99, 255, 0.15)',
                        '&:hover': {
                            backgroundColor: 'rgba(108, 99, 255, 0.2)',
                        },
                    },
                },
            },
        },
        MuiDrawer: {
            styleOverrides: {
                paper: {
                    borderRight: '1px solid rgba(255, 255, 255, 0.05)',
                },
            },
        },
        MuiDivider: {
            styleOverrides: {
                root: {
                    borderColor: 'rgba(255, 255, 255, 0.05)',
                },
            },
        },
    },
});

export const globalStyles = {
    '*': {
        margin: 0,
        padding: 0,
        boxSizing: 'border-box',
    },
    html: {
        fontSize: '16px',
        scrollBehavior: 'smooth',
    },
    body: {
        fontFamily: theme.typography.fontFamily,
        backgroundColor: theme.palette.background.default,
        color: theme.palette.text.primary,
        lineHeight: 1.5,
        overflowX: 'hidden',
    },
    '#root': {
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
    },
    a: {
        color: theme.palette.primary.main,
        textDecoration: 'none',
        transition: 'color 0.2s ease-in-out',
        '&:hover': {
            color: theme.palette.primary.dark,
        },
    },
    '.app': {
        display: 'flex',
        flexDirection: 'column',
        minHeight: '100vh',
    },
    '.container': {
        width: '100%',
        maxWidth: '1280px',
        margin: '0 auto',
        padding: '0 1.5rem',
        flex: '1 0 auto',
    },
    '.page-container': {
        padding: '2rem 0',
        flex: '1 0 auto',
    },
    '.flex': {
        display: 'flex',
    },
    '.flex-col': {
        display: 'flex',
        flexDirection: 'column',
    },
    '.flex-center': {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    '.flex-between': {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    '.flex-start': {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-start',
    },
    '.flex-end': {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
    },
    '.text-center': {
        textAlign: 'center',
    },
    '.text-right': {
        textAlign: 'right',
    },
    '.text-left': {
        textAlign: 'left',
    },
    '.text-gradient': {
        background: 'linear-gradient(45deg, #3a36e0 0%, #6c63ff 100%)',
        WebkitBackgroundClip: 'text',
        WebkitTextFillColor: 'transparent',
    },
    '.card-hover': {
        transition: 'transform 0.3s ease-in-out, box-shadow 0.3s ease-in-out',
        '&:hover': {
            transform: 'translateY(-5px)',
            boxShadow: '0 10px 30px rgba(0, 0, 0, 0.08)',
        },
    },
    '.gradient-bg': {
        background: 'linear-gradient(45deg, #3a36e0 0%, #6c63ff 100%)',
    },
    '.gradient-text': {
        background: 'linear-gradient(45deg, #3a36e0 0%, #6c63ff 100%)',
        WebkitBackgroundClip: 'text',
        WebkitTextFillColor: 'transparent',
    },
    '.truncate': {
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
    },
    '.rounded-full': {
        borderRadius: '9999px',
    },
    '.shadow-sm': {
        boxShadow: '0 1px 2px rgba(0, 0, 0, 0.05)',
    },
    '.shadow': {
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    },
    '.shadow-md': {
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    },
    '.shadow-lg': {
        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
    },
    '.shadow-xl': {
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
    },
    // Spacing utilities
    '.m-0': { margin: '0' },
    '.m-1': { margin: '0.25rem' },
    '.m-2': { margin: '0.5rem' },
    '.m-3': { margin: '1rem' },
    '.m-4': { margin: '1.5rem' },
    '.m-5': { margin: '2rem' },
    '.m-6': { margin: '3rem' },
    '.m-auto': { margin: 'auto' },

    '.mx-0': { marginLeft: '0', marginRight: '0' },
    '.mx-1': { marginLeft: '0.25rem', marginRight: '0.25rem' },
    '.mx-2': { marginLeft: '0.5rem', marginRight: '0.5rem' },
    '.mx-3': { marginLeft: '1rem', marginRight: '1rem' },
    '.mx-4': { marginLeft: '1.5rem', marginRight: '1.5rem' },
    '.mx-5': { marginLeft: '2rem', marginRight: '2rem' },
    '.mx-6': { marginLeft: '3rem', marginRight: '3rem' },
    '.mx-auto': { marginLeft: 'auto', marginRight: 'auto' },

    '.my-0': { marginTop: '0', marginBottom: '0' },
    '.my-1': { marginTop: '0.25rem', marginBottom: '0.25rem' },
    '.my-2': { marginTop: '0.5rem', marginBottom: '0.5rem' },
    '.my-3': { marginTop: '1rem', marginBottom: '1rem' },
    '.my-4': { marginTop: '1.5rem', marginBottom: '1.5rem' },
    '.my-5': { marginTop: '2rem', marginBottom: '2rem' },
    '.my-6': { marginTop: '3rem', marginBottom: '3rem' },
    '.my-auto': { marginTop: 'auto', marginBottom: 'auto' },

    '.mt-0': { marginTop: '0' },
    '.mt-1': { marginTop: '0.25rem' },
    '.mt-2': { marginTop: '0.5rem' },
    '.mt-3': { marginTop: '1rem' },
    '.mt-4': { marginTop: '1.5rem' },
    '.mt-5': { marginTop: '2rem' },
    '.mt-6': { marginTop: '3rem' },
    '.mt-auto': { marginTop: 'auto' },

    '.mb-0': { marginBottom: '0' },
    '.mb-1': { marginBottom: '0.25rem' },
    '.mb-2': { marginBottom: '0.5rem' },
    '.mb-3': { marginBottom: '1rem' },
    '.mb-4': { marginBottom: '1.5rem' },
    '.mb-5': { marginBottom: '2rem' },
    '.mb-6': { marginBottom: '3rem' },
    '.mb-auto': { marginBottom: 'auto' },

    '.ml-0': { marginLeft: '0' },
    '.ml-1': { marginLeft: '0.25rem' },
    '.ml-2': { marginLeft: '0.5rem' },
    '.ml-3': { marginLeft: '1rem' },
    '.ml-4': { marginLeft: '1.5rem' },
    '.ml-5': { marginLeft: '2rem' },
    '.ml-6': { marginLeft: '3rem' },
    '.ml-auto': { marginLeft: 'auto' },

    '.mr-0': { marginRight: '0' },
    '.mr-1': { marginRight: '0.25rem' },
    '.mr-2': { marginRight: '0.5rem' },
    '.mr-3': { marginRight: '1rem' },
    '.mr-4': { marginRight: '1.5rem' },
    '.mr-5': { marginRight: '2rem' },
    '.mr-6': { marginRight: '3rem' },
    '.mr-auto': { marginRight: 'auto' },

    '.p-0': { padding: '0' },
    '.p-1': { padding: '0.25rem' },
    '.p-2': { padding: '0.5rem' },
    '.p-3': { padding: '1rem' },
    '.p-4': { padding: '1.5rem' },
    '.p-5': { padding: '2rem' },
    '.p-6': { padding: '3rem' },

    '.px-0': { paddingLeft: '0', paddingRight: '0' },
    '.px-1': { paddingLeft: '0.25rem', paddingRight: '0.25rem' },
    '.px-2': { paddingLeft: '0.5rem', paddingRight: '0.5rem' },
    '.px-3': { paddingLeft: '1rem', paddingRight: '1rem' },
    '.px-4': { paddingLeft: '1.5rem', paddingRight: '1.5rem' },
    '.px-5': { paddingLeft: '2rem', paddingRight: '2rem' },
    '.px-6': { paddingLeft: '3rem', paddingRight: '3rem' },

    '.py-0': { paddingTop: '0', paddingBottom: '0' },
    '.py-1': { paddingTop: '0.25rem', paddingBottom: '0.25rem' },
    '.py-2': { paddingTop: '0.5rem', paddingBottom: '0.5rem' },
    '.py-3': { paddingTop: '1rem', paddingBottom: '1rem' },
    '.py-4': { paddingTop: '1.5rem', paddingBottom: '1.5rem' },
    '.py-5': { paddingTop: '2rem', paddingBottom: '2rem' },
    '.py-6': { paddingTop: '3rem', paddingBottom: '3rem' },

    '.pt-0': { paddingTop: '0' },
    '.pt-1': { paddingTop: '0.25rem' },
    '.pt-2': { paddingTop: '0.5rem' },
    '.pt-3': { paddingTop: '1rem' },
    '.pt-4': { paddingTop: '1.5rem' },
    '.pt-5': { paddingTop: '2rem' },
    '.pt-6': { paddingTop: '3rem' },

    '.pb-0': { paddingBottom: '0' },
    '.pb-1': { paddingBottom: '0.25rem' },
    '.pb-2': { paddingBottom: '0.5rem' },
    '.pb-3': { paddingBottom: '1rem' },
    '.pb-4': { paddingBottom: '1.5rem' },
    '.pb-5': { paddingBottom: '2rem' },
    '.pb-6': { paddingBottom: '3rem' },

    '.pl-0': { paddingLeft: '0' },
    '.pl-1': { paddingLeft: '0.25rem' },
    '.pl-2': { paddingLeft: '0.5rem' },
    '.pl-3': { paddingLeft: '1rem' },
    '.pl-4': { paddingLeft: '1.5rem' },
    '.pl-5': { paddingLeft: '2rem' },
    '.pl-6': { paddingLeft: '3rem' },

    '.pr-0': { paddingRight: '0' },
    '.pr-1': { paddingRight: '0.25rem' },
    '.pr-2': { paddingRight: '0.5rem' },
    '.pr-3': { paddingRight: '1rem' },
    '.pr-4': { paddingRight: '1.5rem' },
    '.pr-5': { paddingRight: '2rem' },
    '.pr-6': { paddingRight: '3rem' },

    // Responsive utilities
    '@media (max-width: 640px)': {
        '.container': {
            padding: '0 1rem',
        },
        '.hide-sm': {
            display: 'none',
        },
    },
    '@media (min-width: 641px) and (max-width: 768px)': {
        '.hide-md': {
            display: 'none',
        },
    },
    '@media (min-width: 769px) and (max-width: 1024px)': {
        '.hide-lg': {
            display: 'none',
        },
    },
    '@media (min-width: 1025px)': {
        '.hide-xl': {
            display: 'none',
        },
    },
};
