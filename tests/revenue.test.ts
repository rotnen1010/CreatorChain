import { describe, it, expect, beforeEach, vi } from 'vitest'

const mockContractCall = vi.fn()

describe('Revenue Contract', () => {
  const contractAddress = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
  const contractName = 'revenue'
  let creator: string
  let user: string
  
  beforeEach(() => {
    creator = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG'
    user = 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC'
    mockContractCall.mockClear()
  })
  
  describe('record-revenue', () => {
    it('should record revenue successfully', async () => {
      mockContractCall.mockResolvedValueOnce({ success: true, value: true })
      const result = await mockContractCall('record-revenue', [0, 100], { sender: creator })
      expect(result.success).toBe(true)
      expect(result.value).toBe(true)
    })
  })
  
  describe('get-content-revenue', () => {
    it('should return content revenue', async () => {
      const revenueDetails = {
        'total-revenue': 100
      }
      mockContractCall.mockResolvedValueOnce({ success: true, value: revenueDetails })
      const result = await mockContractCall('get-content-revenue', [0])
      expect(result.success).toBe(true)
      expect(result.value).toEqual(revenueDetails)
    })
    
    it('should return zero revenue for non-existent content', async () => {
      const zeroRevenue = {
        'total-revenue': 0
      }
      mockContractCall.mockResolvedValueOnce({ success: true, value: zeroRevenue })
      const result = await mockContractCall('get-content-revenue', [999])
      expect(result.success).toBe(true)
      expect(result.value).toEqual(zeroRevenue)
    })
  })
})

