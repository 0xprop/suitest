import React, { useState, useEffect } from 'react';
import { ConnectButton, useWallet } from '@suiet/wallet-kit';
import '@suiet/wallet-kit/style.css';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { SuiClient } from '@mysten/sui.js/client';

const PACKAGE_ID = process.env.REACT_APP_PACKAGE_ID || ''; // Provide a default value

const App = () => {
  const [address, setAddress] = useState('');
  const [titleStatus, setTitleStatus] = useState('');
  const [propertyValue, setPropertyValue] = useState('');
  const [feedback, setFeedback] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [deeds, setDeeds] = useState([]);
  const [recipientAddress, setRecipientAddress] = useState('');
  const { connected, signAndExecuteTransactionBlock, account } = useWallet();

  useEffect(() => {
    if (connected && account) {
      fetchDeeds();
    } else {
      setDeeds([]);
    }
  }, [connected, account]);

  const fetchDeeds = async () => {
    if (!connected || !account) return;
    
    const client = new SuiClient({ url: 'https://fullnode.testnet.sui.io:443' });
    try {
      const ownedObjects = await client.getOwnedObjects({
        owner: account.address,
        options: { showContent: true },
      });
      
      const filteredDeeds = ownedObjects.data.filter(obj => 
        obj.data?.content?.type?.includes(`${PACKAGE_ID}::deed::RealEstateDeed`)
      );
      
      setDeeds(filteredDeeds);
      console.log('Fetched deeds:', filteredDeeds);
    } catch (error) {
      console.error('Error fetching deeds:', error);
      setFeedback('Error fetching deeds. Please try again.');
    }
  };

  const mintDeed = async () => {
    if (!connected) {
      setFeedback('Please connect your wallet first');
      return;
    }
    if (!PACKAGE_ID) {
      setFeedback('PACKAGE_ID is not set. Please check your environment variables.');
      return;
    }
    setIsLoading(true);
    setFeedback('');
    try {
      const tx = new TransactionBlock();
      tx.moveCall({
        target: `${PACKAGE_ID}::deed::mint_deed`,
        arguments: [
          tx.pure.address(account.address),
          tx.pure.string(address),
          tx.pure.string(titleStatus),
          tx.pure.u64(propertyValue),
        ],
      });

      console.log('Minting deed with args:', account.address, address, titleStatus, propertyValue);

      const result = await signAndExecuteTransactionBlock({
        transactionBlock: tx,
      });

      console.log('Minted deed:', result);
      setFeedback('Deed minted successfully!');
      fetchDeeds();
    } catch (e) {
      console.error('Error minting deed:', e);
      setFeedback(`Error: ${e.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const transferDeed = async (deedId) => {
    if (!connected || !recipientAddress) {
      setFeedback('Please connect your wallet and enter a recipient address');
      return;
    }
    setIsLoading(true);
    setFeedback('');
    try {
      const tx = new TransactionBlock();
      tx.moveCall({
        target: `${PACKAGE_ID}::deed::transfer_deed`,
        arguments: [
          tx.object(deedId),
          tx.pure.address(recipientAddress),
        ],
      });

      const result = await signAndExecuteTransactionBlock({
        transactionBlock: tx,
      });

      console.log('Transferred deed:', result);
      setFeedback('Deed transferred successfully!');
      fetchDeeds();
    } catch (e) {
      console.error('Error transferring deed:', e);
      setFeedback(`Error: ${e.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const updateTitleStatus = async (deedId, newStatus) => {
    if (!connected) {
      setFeedback('Please connect your wallet first');
      return;
    }
    setIsLoading(true);
    setFeedback('');
    try {
      const tx = new TransactionBlock();
      tx.moveCall({
        target: `${PACKAGE_ID}::deed::update_title_status`,
        arguments: [
          tx.object(deedId),
          tx.pure.string(newStatus),
        ],
      });

      const result = await signAndExecuteTransactionBlock({
        transactionBlock: tx,
      });

      console.log('Updated deed title status:', result);
      setFeedback('Deed title status updated successfully!');
      fetchDeeds();
    } catch (e) {
      console.error('Error updating deed title status:', e);
      setFeedback(`Error: ${e.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const updatePropertyValue = async (deedId, newValue) => {
    if (!connected) {
      setFeedback('Please connect your wallet first');
      return;
    }
    setIsLoading(true);
    setFeedback('');
    try {
      const tx = new TransactionBlock();
      tx.moveCall({
        target: `${PACKAGE_ID}::deed::update_property_value`,
        arguments: [
          tx.object(deedId),
          tx.pure.u64(newValue),
        ],
      });

      const result = await signAndExecuteTransactionBlock({
        transactionBlock: tx,
      });

      console.log('Updated deed property value:', result);
      setFeedback('Deed property value updated successfully!');
      fetchDeeds();
    } catch (e) {
      console.error('Error updating deed property value:', e);
      setFeedback(`Error: ${e.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
      <h1>Real Estate NFT Manager</h1>
      <ConnectButton />
      <h2>Mint New Deed</h2>
      <input
        style={{ display: 'block', width: '100%', marginBottom: '10px', padding: '5px' }}
        placeholder="Address"
        value={address}
        onChange={(e) => setAddress(e.target.value)}
      />
      <input
        style={{ display: 'block', width: '100%', marginBottom: '10px', padding: '5px' }}
        placeholder="Title Status"
        value={titleStatus}
        onChange={(e) => setTitleStatus(e.target.value)}
      />
      <input
        style={{ display: 'block', width: '100%', marginBottom: '10px', padding: '5px' }}
        placeholder="Property Value"
        type="number"
        value={propertyValue}
        onChange={(e) => setPropertyValue(e.target.value)}
      />
      <button 
        onClick={mintDeed} 
        disabled={isLoading}
        style={{ display: 'block', width: '100%', padding: '10px', backgroundColor: '#4CAF50', color: 'white', border: 'none', marginBottom: '20px' }}
      >
        {isLoading ? 'Minting...' : 'Mint Deed'}
      </button>

      <h2>Your Deeds</h2>
      {deeds.map((deed) => (
        <div key={deed.data.objectId} style={{ border: '1px solid #ccc', padding: '10px', marginBottom: '10px' }}>
          <p>Deed ID: {deed.data.objectId}</p>
          <input
            style={{ width: '100%', marginBottom: '5px', padding: '5px' }}
            placeholder="Recipient Address"
            onChange={(e) => setRecipientAddress(e.target.value)}
          />
          <button onClick={() => transferDeed(deed.data.objectId)}>Transfer Deed</button>
          <input
            style={{ width: '100%', marginBottom: '5px', padding: '5px' }}
            placeholder="New Title Status"
            onChange={(e) => updateTitleStatus(deed.data.objectId, e.target.value)}
          />
          <input
            style={{ width: '100%', marginBottom: '5px', padding: '5px' }}
            type="number"
            placeholder="New Property Value"
            onChange={(e) => updatePropertyValue(deed.data.objectId, e.target.value)}
          />
        </div>
      ))}

      {feedback && <p style={{ marginTop: '10px', color: feedback.includes('Error') ? 'red' : 'green' }}>{feedback}</p>}
    </div>
  );
};

export default App;
