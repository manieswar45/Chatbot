import React from 'react';
import { ChakraProvider, theme } from '@chakra-ui/react';
import ChatInterface from './components/ChatInterface';

function App() {
  return (
    <ChakraProvider theme={theme}>
      <ChatInterface />
    </ChakraProvider>
  );
}

export default App;