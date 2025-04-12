import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  InputAdornment,
  IconButton,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import FilterListIcon from '@mui/icons-material/FilterList';

const Transactions = () => {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchQuery, setSearchQuery] = useState('');

  // Sample transaction data
  const transactions = [
    {
      id: 1,
      hash: '0x1234...5678',
      type: 'Transfer',
      amount: '1.5 ETH',
      status: 'Completed',
      timestamp: '2023-04-01 12:30:45',
    },
    {
      id: 2,
      hash: '0x2345...6789',
      type: 'Smart Contract',
      amount: '0.8 ETH',
      status: 'Pending',
      timestamp: '2023-04-01 12:25:30',
    },
    // Add more sample transactions as needed
  ];

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const filteredTransactions = transactions.filter((transaction) =>
    Object.values(transaction).some((value) =>
      value.toString().toLowerCase().includes(searchQuery.toLowerCase())
    )
  );

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h4" gutterBottom>
        Transactions
      </Typography>

      {/* Search and Filter Bar */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <TextField
            fullWidth
            variant="outlined"
            placeholder="Search transactions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
          />
          <IconButton color="primary">
            <FilterListIcon />
          </IconButton>
        </Box>
      </Paper>

      {/* Transactions Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Transaction Hash</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Amount</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Timestamp</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredTransactions
              .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
              .map((transaction) => (
                <TableRow key={transaction.id}>
                  <TableCell>{transaction.hash}</TableCell>
                  <TableCell>{transaction.type}</TableCell>
                  <TableCell>{transaction.amount}</TableCell>
                  <TableCell>
                    <Box
                      sx={{
                        display: 'inline-block',
                        px: 1,
                        py: 0.5,
                        borderRadius: 1,
                        bgcolor:
                          transaction.status === 'Completed'
                            ? 'success.light'
                            : 'warning.light',
                        color:
                          transaction.status === 'Completed'
                            ? 'success.dark'
                            : 'warning.dark',
                      }}
                    >
                      {transaction.status}
                    </Box>
                  </TableCell>
                  <TableCell>{transaction.timestamp}</TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={filteredTransactions.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </TableContainer>
    </Container>
  );
};

export default Transactions; 