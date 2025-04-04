import { useEffect, useState } from 'react';  
import { useWeb3 } from './web3-provider';  

export default function useProtocolData() {  
    const { contract } = useWeb3();  
    const [positions, setPositions] = useState([]);  

    useEffect(() => {  
        const fetchPositions = async () => {  
            const filter = contract.filters.PositionCreated();  
            const events = await contract.queryFilter(filter);  
            const positions = await Promise.all(  
                events.map(async (e) => {  
                    const pos = await contract.positions(e.args.positionId);  
                    return {  
                        id: e.args.positionId,  
                        allocations: pos.allocations,  
                        risk: pos.riskScore  
                    };  
                })  
            );  
            setPositions(positions);  
        };  
        fetchPositions();  
    }, [contract]);  

    return { positions };  
}  