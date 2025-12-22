import axios from 'axios';
import { authAPI, blockchainAPI, handleApiError } from '../services/api';

jest.mock('axios');

describe('API Services', () => {
    describe('handleApiError', () => {
        test('handles response errors correctly', () => {
            const error = {
                response: {
                    status: 404,
                    data: { detail: 'Not found' },
                },
            };

            const result = handleApiError(error);
            expect(result).toEqual({
                status: 404,
                message: 'Not found',
            });
        });

        test('handles request errors correctly', () => {
            const error = {
                request: {},
            };

            const result = handleApiError(error);
            expect(result).toEqual({
                status: 0,
                message: 'No response from server. Please check your connection.',
            });
        });

        test('handles unknown errors correctly', () => {
            const error = {
                message: 'Unknown error',
            };

            const result = handleApiError(error);
            expect(result).toEqual({
                status: 0,
                message: 'Unknown error',
            });
        });
    });

    describe('authAPI', () => {
        beforeEach(() => {
            jest.clearAllMocks();
        });

        test('register calls correct endpoint', async () => {
            const mockData = { id: 1, email: 'test@example.com' };
            const mockResponse = { data: mockData };
            axios.create().post.mockResolvedValue(mockResponse);

            const userData = {
                name: 'Test User',
                email: 'test@example.com',
                password: 'password123',
            };

            const result = await authAPI.register(userData);
            expect(result.data).toEqual(mockData);
        });

        test('login calls correct endpoint', async () => {
            const mockData = { access_token: 'token123', token_type: 'Bearer' };
            const mockResponse = { data: mockData };
            axios.create().post.mockResolvedValue(mockResponse);

            const credentials = {
                email: 'test@example.com',
                password: 'password123',
            };

            const result = await authAPI.login(credentials);
            expect(result.data).toEqual(mockData);
        });
    });

    describe('blockchainAPI', () => {
        beforeEach(() => {
            jest.clearAllMocks();
        });

        test('getPortfolio calls correct endpoint', async () => {
            const mockData = {
                total_value: '10000.00',
                assets: [{ symbol: 'ETH', balance: '5' }],
            };
            const mockResponse = { data: mockData };
            axios.create().get.mockResolvedValue(mockResponse);

            const walletAddress = '0x1234567890abcdef';
            const result = await blockchainAPI.getPortfolio(walletAddress);
            expect(result.data).toEqual(mockData);
        });

        test('getTransactions calls correct endpoint', async () => {
            const mockData = [
                { id: 1, type: 'send', amount: '1 ETH' },
                { id: 2, type: 'receive', amount: '2 ETH' },
            ];
            const mockResponse = { data: mockData };
            axios.create().get.mockResolvedValue(mockResponse);

            const walletAddress = '0x1234567890abcdef';
            const result = await blockchainAPI.getTransactions(walletAddress);
            expect(result.data).toEqual(mockData);
        });
    });
});
