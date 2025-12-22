'use client';
import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
    Box,
    Typography,
    CircularProgress,
    Alert,
    List,
    ListItem,
    ListItemText,
    Divider,
} from '@mui/material';
import { useTransactionHistory } from '../hooks/useProtocolData'; // Assuming this hook exists

const TransactionsPage = () => {
    const router = useRouter();
    const { transactions, loading, error } = useTransactionHistory(); // Placeholder hook

    // Example of a placeholder transaction data structure
    const mockTransactions = [
        { id: 1, type: 'Deposit', amount: 500, date: '2024-10-01', status: 'Completed' },
        { id: 2, type: 'Loan Repayment', amount: 150, date: '2024-10-05', status: 'Completed' },
        { id: 3, type: 'Withdrawal', amount: 200, date: '2024-10-10', status: 'Pending' },
    ];

    const displayTransactions = transactions || mockTransactions;

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box sx={{ p: 2 }}>
            <Typography variant="h5" gutterBottom>
                Transaction History
            </Typography>

            {error && (
                <Alert severity="error" sx={{ mb: 3 }}>
                    {error}
                </Alert>
            )}

            <List>
                {displayTransactions.length === 0 ? (
                    <Typography sx={{ mt: 2 }}>No transactions found.</Typography>
                ) : (
                    displayTransactions.map((tx, index) => (
                        <React.Fragment key={tx.id}>
                            <ListItem>
                                <ListItemText
                                    primary={`${tx.type}: $${tx.amount}`}
                                    secondary={`Date: ${tx.date} | Status: ${tx.status}`}
                                />
                            </ListItem>
                            {index < displayTransactions.length - 1 && <Divider />}
                        </React.Fragment>
                    ))
                )}
            </List>
        </Box>
    );
};

export default TransactionsPage;
