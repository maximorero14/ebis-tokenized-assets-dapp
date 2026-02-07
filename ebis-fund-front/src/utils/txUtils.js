export const waitForTransaction = async (tx, provider, timeoutMs = 15000) => {
    // Promise that rejects after timeout
    const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => {
            reject(new Error('TIMEOUT'));
        }, timeoutMs);
    });

    try {
        // Race standard wait against timeout
        const receipt = await Promise.race([
            tx.wait(1),
            timeoutPromise
        ]);
        return receipt;
    } catch (error) {
        if (error.message === 'TIMEOUT') {
            console.warn(`Transaction wait timed out after ${timeoutMs}ms. Checking receipt manually...`);
            // Check if transaction was actually mined
            try {
                const receipt = await provider.getTransactionReceipt(tx.hash);
                if (receipt && receipt.blockNumber) {
                    console.log('Manual receipt check successful:', receipt);
                    return receipt;
                } else {
                    console.warn('Manual check: Transaction still pending or not found.');
                    console.log('Transaction taking longer than expected. Reloading page...');
                    //window.location.reload();
                    // Return a dummy receipt to prevent further errors before reload
                    return { hash: tx.hash, status: 'pending' };
                }
            } catch (manualError) {
                throw manualError;
            }
        } else {
            // Re-throw other errors (e.g. revert)
            throw error;
        }
    }
};
