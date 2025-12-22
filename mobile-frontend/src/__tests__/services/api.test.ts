import axios from 'axios';
import { authAPI, handleApiError } from '@/services/api';
import type { ApiError } from '@/services/api';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('API Service', () => {
    describe('handleApiError', () => {
        it('handles response errors correctly', () => {
            const error = {
                response: {
                    status: 400,
                    data: { detail: 'Bad request' },
                },
            };

            const result = handleApiError(error);
            expect(result).toEqual({
                status: 400,
                message: 'Bad request',
            });
        });

        it('handles network errors correctly', () => {
            const error = {
                request: {},
            };

            const result = handleApiError(error);
            expect(result).toEqual({
                status: 0,
                message: 'No response from server. Please check your connection.',
            });
        });

        it('handles unknown errors correctly', () => {
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
});
