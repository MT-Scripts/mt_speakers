import React from 'react'
import ReactDOM from 'react-dom/client'
import { VisibilityProvider } from './providers/VisibilityProvider'
import { MantineProvider } from '@mantine/core'
import { ModalsProvider } from '@mantine/modals'
import { DatesProvider } from '@mantine/dates'
import SpeakersMenu from './components/SpeakersMenu'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MantineProvider  theme={{ colorScheme:'dark' }}>
      <ModalsProvider>
        <VisibilityProvider componentName="SpeakersMenu">
          <SpeakersMenu/>
        </VisibilityProvider>
      </ModalsProvider>
    </MantineProvider>
  </React.StrictMode>
)