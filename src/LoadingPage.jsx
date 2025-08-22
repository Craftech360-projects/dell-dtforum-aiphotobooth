// eslint-disable-next-line no-unused-vars
import React from 'react';
import styled, { keyframes } from 'styled-components';

const rotation = keyframes`
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
`;

const rotationBack = keyframes`
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(-360deg);
  }
`;

const LoaderWrapper = styled.div`
  width: 200px; /* Increased size */
  height: 200px; /* Increased size */
  border: 16px dotted #FFF; /* Increased size */
  border-style: solid solid dotted dotted;
  border-radius: 50%;
  display: inline-block;
  position: relative;
  box-sizing: border-box;
  animation: ${rotation} 2s linear infinite;
`;

const LoaderInner = styled.div`
  content: '';  
  box-sizing: border-box;
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  margin: auto;
  border: 16px dotted #30A6EC; /* Increased size */
  border-style: solid solid dotted;
  width: 100px; /* Increased size */
  height: 100px; /* Increased size */
  border-radius: 50%;
  animation: ${rotationBack} .5s linear infinite;
  transform-origin: center center;
`;



function LoadingPage() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '100vh', width: '100vw' }}>
      <LoaderWrapper>
        <LoaderInner />
      </LoaderWrapper>
    </div>
  );
}

export default LoadingPage;
