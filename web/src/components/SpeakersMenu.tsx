import React, { useState, useEffect, useRef } from "react"
import { DEFAULT_THEME, Divider, Paper, Text, Group, Switch, ScrollArea, ThemeIcon, CloseButton, Tabs, Image, Input, TextInput, Button, ActionIcon, Tooltip, Slider } from '@mantine/core'
import { modals } from '@mantine/modals'
import { fetchNui } from "../utils/fetchNui"
import { useNuiEvent } from "../hooks/useNuiEvent"
import { FaCheck, FaExchangeAlt, FaPause, FaPlay, FaPlus, FaTrashAlt } from "react-icons/fa";
import { FaXmark } from "react-icons/fa6";

interface Musics {
    musicId: number,
    citizenid: string,
    label: string,
    url: string
}

interface Accesses {
    citizenid: string,
    name: string
}

const SpeakersMenu: React.FC = () => {
    const theme = DEFAULT_THEME;
    const url = useRef<any>('');
    const urlAdd = useRef<any>('');
    const labelAdd = useRef<any>('');
    const [speakerId, setSpeakerId] = useState<number>(0);
    const [speakerName, setSpeakerName] = useState<string>('');
    const [maxVolume, setMaxVolume] = useState<number>(1);
    const [maxDistance, setMaxDistance] = useState<number>(1);
    const [volume, setVolume] = useState<number>(0);
    const [distance, setDistance] = useState<number>(0);
    const [musicPlaying, setMusicPlaying] = useState<boolean>(false);
    const [isPaused, setIsPaused] = useState<boolean>(false);
    const [musics, setMusics] = useState<Musics[]>([]);
    const [accesses, setAccesses] = useState<Accesses[]>([]);
    const [closePlayers, setClosePlayers] = useState<any[]>([]);

    useNuiEvent<any>('setSpeakerSettings', (data) => {
        setSpeakerId(data.speakerId);
        setSpeakerName(data.speakerName);
        setMaxVolume(data.maxVolume);
        setMaxDistance(data.maxDistance);
        setMusicPlaying(data.musicPlaying);
        if (data.musicPlaying) {
            setVolume(data.volume);
            setDistance(data.distance);
            setIsPaused(data.isPaused);
        }
    });

    useNuiEvent<any>('resetSpeakerSettings', (data) => {
        setSpeakerId(0);
        setSpeakerName('');
        setMaxVolume(0);
        setMaxDistance(0);
        setVolume(0);
        setDistance(0);
    });

    useNuiEvent<any>('setSpeakersSongs', (data) => setMusics(data));

    useNuiEvent<any>('setSpeakerAccesses', (data) => {
        setAccesses(data.users);
        setClosePlayers(data.close);
    });

    return (
        <div style={{ width: '100%', height: '100%', position: 'fixed' }}>
            <Paper w={350} withBorder radius="sm" style={{ margin: 15, backgroundColor: theme.colors.dark[8], position: 'absolute', right: 200, top: 400 }}>
                <Group style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: 5 }}>
                    <Text size="md" fw={700}>{speakerName}</Text>
                    <CloseButton size="sm" color="red" variant="light" onClick={() => fetchNui('hideFrame', { name: 'SpeakersMenu' })} />
                </Group>
                <Divider />
                <Tabs defaultValue="playing" variant="pills" color="dark.6">
                    <Tabs.List style={{ gap: 0 }} grow>
                        <Tabs.Tab style={{ borderRadius: 0 }} value="playing">Playing</Tabs.Tab>
                        <Tabs.Tab style={{ borderRadius: 0 }} value="musics">Musics</Tabs.Tab>
                        <Tabs.Tab style={{ borderRadius: 0 }} value="access">Accesses</Tabs.Tab>
                    </Tabs.List>

                    <Divider />

                    <Tabs.Panel value="playing" style={{ padding: 10, height: '100%' }}>
                        <Group style={{ display: 'flex', alignItems: 'flex-end', gap: 5, width: '100%', border: `1px solid ${theme.colors.dark[4]}`, borderRadius: theme.radius.sm, padding: 5, paddingTop: 0 }}>
                            <TextInput ref={url} w={211} size="xs" placeholder="https://www.youtube.com/watch?v=MUSICID" label="Music URL" description="Only youtube links" />
                            <Tooltip label="Resume" color="dark.6">
                                <ActionIcon disabled={(!musicPlaying || !isPaused)} variant="light" color="green" size={30} onClick={() => fetchNui('songActions', { action: 'resume', speakerId: speakerId })}>
                                    <FaPlay />
                                </ActionIcon>
                            </Tooltip>
                            <Tooltip label="Pause" color="dark.6">
                                <ActionIcon disabled={(!musicPlaying || isPaused)} variant="light" color="red" size={30} onClick={() => fetchNui('songActions', { action: 'pause', speakerId: speakerId })}>
                                    <FaPause />
                                </ActionIcon>
                            </Tooltip>
                            <Tooltip label="Change" color="dark.6">
                                <ActionIcon variant="light" color="violet" size={30} onClick={() => {
                                    if (url.current?.value.match(/^(http(s)?:\/\/)?((w){3}.)?youtu(be|.be)?(\.com)?\/.+/gm)) fetchNui('songActions', { action: 'play', speakerId: speakerId, url: url.current?.value })
                                }}>
                                    <FaExchangeAlt />
                                </ActionIcon>
                            </Tooltip>
                        </Group>

                        <Group mt={10} style={{ display: 'flex', alignItems: 'flex-end', gap: 5, width: '100%', border: `1px solid ${theme.colors.dark[4]}`, borderRadius: theme.radius.sm, padding: 5 }}>
                            <Group style={{ gap: 0, width: '100%' }}>
                                <Text size="xs" fw={600}>Volume</Text>
                                <Slider value={volume} onChange={setVolume} max={maxVolume} w="100%" />
                            </Group>
                            <Group style={{ gap: 0, width: '100%' }}>
                                <Text size="xs" fw={600}>Distance</Text>
                                <Slider value={distance} onChange={setDistance} max={maxDistance} w="100%" />
                            </Group>
                            <Button color="green" variant="light" size="xs" style={{ width: '100%', marginTop: 10 }} onClick={() => fetchNui('songActions', { action: 'update', volume: volume, distance: distance, speakerId: speakerId })}>Update volume and distance</Button>
                        </Group>
                    </Tabs.Panel>

                    <Tabs.Panel value="musics" style={{ padding: 10, height: '100%' }}>
                        <ScrollArea scrollHideDelay={0} scrollbarSize={2} mah={500} style={{ display: 'flex', flexDirection: 'column' }}>
                            {musics.length > 0 ? musics.map(({ musicId, citizenid, label, url: musicUrl }) => (
                                <Group mb={5} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', border: `1px solid ${theme.colors.dark[4]}`, borderRadius: theme.radius.sm, padding: 5 }}>
                                    <Text fw={600}>{label}</Text>
                                    <Group spacing={5}>
                                        <Tooltip label="Play" color="dark.6">
                                            <ActionIcon size="sm" variant="light" color="green" onClick={() => fetchNui('songActions', { action: 'play', speakerId: speakerId, url: musicUrl })}>
                                                <FaPlay size={12} />
                                            </ActionIcon>
                                        </Tooltip>

                                        <Tooltip label="Delete" color="dark.6">
                                            <ActionIcon size="sm" variant="light" color="red" onClick={() => fetchNui('deleteMusic', { musicId: musicId })}>
                                                <FaTrashAlt size={12} />
                                            </ActionIcon>
                                        </Tooltip>
                                    </Group>
                                </Group>
                            )) : <Text align="center" size="sm">No musics added</Text>}
                        </ScrollArea>

                        <Button color="green" variant="light" size="xs" style={{ width: '100%', marginTop: 10 }} leftIcon={<FaPlus />} onClick={() => {
                            modals.open({
                                title: 'Add Music',
                                centered: true,
                                size: 'sm',
                                sx: {
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    height: '100%',
                                    fontFamily: 'sans-serif',
                                    '.mantine-Modal-modal': {
                                        margin: 'auto',
                                        top: 0,
                                        bottom: 0,
                                    },
                                },
                                children: (
                                    <Group spacing={10} style={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                                        <TextInput ref={urlAdd} w="100%" placeholder="https://www.youtube.com/watch?v=MUSICID" label="Music URL" description="Only youtube links" withAsterisk />
                                        <TextInput ref={labelAdd} w="100%" placeholder="Music label" label="Music label" description="Label to identify the music" withAsterisk />
                                        <Button color="green" variant="light" style={{ width: '100%' }} leftIcon={<FaCheck />} onClick={() => {
                                            if (urlAdd.current?.value.match(/^(http(s)?:\/\/)?((w){3}.)?youtu(be|.be)?(\.com)?\/.+/gm) && labelAdd.current?.value) {
                                                fetchNui('addMusic', { url: urlAdd.current?.value, label: labelAdd.current?.value })
                                                modals.closeAll()
                                            }
                                        }}>Add Music</Button>
                                    </Group>
                                )
                            })
                        }}>Add Music</Button>
                    </Tabs.Panel>

                    <Tabs.Panel value="access" style={{ padding: 10, height: '100%' }}>
                        <Divider label="Added players" />
                        {accesses.length > 0 ? accesses.map(({ name, citizenid }) => (
                            <Group mb={5} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', border: `1px solid ${theme.colors.dark[4]}`, borderRadius: theme.radius.sm, padding: 5 }}>
                                <Text fw={600}>{name} ({citizenid})</Text>
                                <Group spacing={5}>
                                    <Tooltip label="Remove" color="dark.6" onClick={() => fetchNui('removeAccess', { user: { name, citizenid }, speakerId })}>
                                        <ActionIcon size="sm" variant="light" color="red">
                                            <FaXmark size={12} />
                                        </ActionIcon>
                                    </Tooltip>
                                </Group>
                            </Group>
                        )) : <Text align="center" size="sm">No players added</Text>}

                        <Divider mt={10} label="Players close" />
                        {closePlayers.length > 0 ? closePlayers.map(({ name, citizenid }) => (
                            <Group mb={5} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', border: `1px solid ${theme.colors.dark[4]}`, borderRadius: theme.radius.sm, padding: 5 }}>
                                <Text fw={600}>{name} ({citizenid})</Text>
                                <Group spacing={5}>
                                    <Tooltip label="Add" color="dark.6" onClick={() => fetchNui('addAccess', { user: { name, citizenid }, speakerId })}>
                                        <ActionIcon size="sm" variant="light" color="green">
                                            <FaPlus size={12} />
                                        </ActionIcon>
                                    </Tooltip>
                                </Group>
                            </Group>
                        )) : <Text align="center" size="sm">No players close</Text>}
                    </Tabs.Panel>
                </Tabs>
            </Paper>
        </div>
    );
}

export default SpeakersMenu;