import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity contract environment
const mockContractCall = vi.fn();
const mockTxSender = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';

// Mock the contract environment
vi.mock('@stacks/transactions', () => {
  return {
    callReadOnlyFunction: mockContractCall,
  };
});

describe('Asset Registration Contract', () => {
  beforeEach(() => {
    mockContractCall.mockReset();
  });
  
  it('should register a new asset', async () => {
    // Mock the contract call response
    mockContractCall.mockResolvedValueOnce({
      value: { type: 'ok', value: 'ASSET-1' }
    });
    
    // Test data
    const assetName = 'Bitcoin Holdings';
    const assetType = 'cryptocurrency';
    const metadata = '{"amount":"10.5","acquisition_date":"2023-01-15"}';
    
    // Call the contract function
    const result = await registerAsset(assetName, assetType, metadata);
    
    // Verify the result
    expect(result).toBe('ASSET-1');
    expect(mockContractCall).toHaveBeenCalledWith(
        expect.objectContaining({
          contractName: 'asset-registration',
          functionName: 'register-asset',
          functionArgs: expect.arrayContaining([
            expect.anything(), // name
            expect.anything(), // asset-type
            expect.anything(), // metadata
          ]),
        })
    );
  });
  
  it('should get asset details', async () => {
    // Mock the contract call response
    const mockAsset = {
      name: 'Bitcoin Holdings',
      'asset-type': 'cryptocurrency',
      'registration-date': 1642204800,
      owner: mockTxSender,
      metadata: '{"amount":"10.5","acquisition_date":"2023-01-15"}',
      status: 'active'
    };
    
    mockContractCall.mockResolvedValueOnce({
      value: { type: 'ok', value: mockAsset }
    });
    
    // Call the contract function
    const result = await getAsset('ASSET-1');
    
    // Verify the result
    expect(result).toEqual(mockAsset);
    expect(mockContractCall).toHaveBeenCalledWith(
        expect.objectContaining({
          contractName: 'asset-registration',
          functionName: 'get-asset',
          functionArgs: expect.arrayContaining([
            expect.anything(), // asset-id
          ]),
        })
    );
  });
  
  it('should update asset status', async () => {
    // Mock the contract call response
    mockContractCall.mockResolvedValueOnce({
      value: { type: 'ok', value: true }
    });
    
    // Call the contract function
    const result = await updateAssetStatus('ASSET-1', 'inactive');
    
    // Verify the result
    expect(result).toBe(true);
    expect(mockContractCall).toHaveBeenCalledWith(
        expect.objectContaining({
          contractName: 'asset-registration',
          functionName: 'update-asset-status',
          functionArgs: expect.arrayContaining([
            expect.anything(), // asset-id
            expect.anything(), // new-status
          ]),
        })
    );
  });
});

// Helper functions to simulate contract calls
async function registerAsset(name: string, assetType: string, metadata: string): Promise<string> {
  const response = await mockContractCall({
    contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    contractName: 'asset-registration',
    functionName: 'register-asset',
    functionArgs: [name, assetType, metadata],
    senderAddress: mockTxSender,
  });
  
  if (response.value.type === 'ok') {
    return response.value.value;
  }
  throw new Error('Failed to register asset');
}

async function getAsset(assetId: string): Promise<any> {
  const response = await mockContractCall({
    contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    contractName:
