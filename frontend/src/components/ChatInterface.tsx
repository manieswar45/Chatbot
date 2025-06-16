import React, { useState, useEffect, useRef } from 'react';
import { Box, Flex, Input, Button, Text, VStack, HStack, useColorMode, IconButton } from '@chakra-ui/react';
import { SendIcon, MicrophoneIcon, AttachmentIcon, SunIcon, MoonIcon } from './Icons';

interface Message {
  id: string;
  content: string;
  sender: 'user' | 'bot';
  timestamp: Date;
}

const ChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const { colorMode, toggleColorMode } = useColorMode();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom of messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async () => {
    if (!input.trim()) return;
    
    // Add user message to chat
    const userMessage: Message = {
      id: Date.now().toString(),
      content: input,
      sender: 'user',
      timestamp: new Date()
    };
    
    setMessages(prevMessages => [...prevMessages, userMessage]);
    setInput('');
    setIsLoading(true);
    
    try {
      // Call API to get bot response
      const response = await fetch('http://localhost:3001/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message: input }),
      });
      
      const data = await response.json();
      
      // Add bot message to chat
      const botMessage: Message = {
        id: (Date.now() + 1).toString(),
        content: data.message,
        sender: 'bot',
        timestamp: new Date()
      };
      
      setMessages(prevMessages => [...prevMessages, botMessage]);
    } catch (error) {
      console.error('Error fetching bot response:', error);
      
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        content: 'Sorry, I encountered an error. Please try again later.',
        sender: 'bot',
        timestamp: new Date()
      };
      
      setMessages(prevMessages => [...prevMessages, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Flex direction="column" h="100vh" maxW="800px" mx="auto" p={4}>
      <Flex justifyContent="space-between" mb={4} alignItems="center">
        <Text fontSize="xl" fontWeight="bold">AI Assistant</Text>
        <IconButton
          aria-label="Toggle color mode"
          icon={colorMode === 'light' ? <MoonIcon /> : <SunIcon />}
          onClick={toggleColorMode}
          variant="ghost"
        />
      </Flex>

      <VStack
        flex={1}
        overflowY="auto"
        spacing={4}
        p={4}
        borderRadius="md"
        bg={colorMode === 'light' ? 'gray.50' : 'gray.700'}
      >
        {messages.map(message => (
          <Box
            key={message.id}
            alignSelf={message.sender === 'user' ? 'flex-end' : 'flex-start'}
            bg={message.sender === 'user' ? 'blue.500' : colorMode === 'light' ? 'gray.200' : 'gray.600'}
            color={message.sender === 'user' ? 'white' : colorMode === 'light' ? 'black' : 'white'}
            p={3}
            borderRadius="lg"
            maxW="70%"
          >
            <Text>{message.content}</Text>
            <Text fontSize="xs" textAlign="right" mt={1} opacity={0.7}>
              {message.timestamp.toLocaleTimeString()}
            </Text>
          </Box>
        ))}
        {isLoading && (
          <Box alignSelf="flex-start" bg={colorMode === 'light' ? 'gray.200' : 'gray.600'} p={3} borderRadius="lg">
            <Text>Thinking...</Text>
          </Box>
        )}
        <div ref={messagesEndRef} />
      </VStack>

      <HStack mt={4}>
        <IconButton aria-label="Attach file" icon={<AttachmentIcon />} variant="ghost" />
        <IconButton aria-label="Voice input" icon={<MicrophoneIcon />} variant="ghost" />
        <Input 
          placeholder="Type your message..." 
          value={input} 
          onChange={(e) => setInput(e.target.value)} 
          onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
        />
        <Button 
          colorScheme="blue" 
          onClick={handleSendMessage} 
          isLoading={isLoading}
        >
          <SendIcon />
        </Button>
      </HStack>
    </Flex>
  );
};

export default ChatInterface;