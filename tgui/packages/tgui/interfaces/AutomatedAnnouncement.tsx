import { filter, sortBy } from 'common/collections';
import { useState } from 'react';
import {
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type AASConfigEntry = {
  name: string;
  entryRef: string;
  enabled: BooleanLike;
  modifiable: BooleanLike;
  announcementLinesMap: Record<string, string>;
  generalTooltip: string;
  varsAndTooltipsMap: Record<string, string>;
};

type Data = {
  config_entries: AASConfigEntry[];
};

export const AutomatedAnnouncement = (props) => {
  const { act, data } = useBackend<Data>();
  const { config_entries = [] } = data;

  const [search, setSearch] = useState('');

  const isEntryMatch = (entry: AASConfigEntry, search: string) => {
    if (!search) return true;
    const { name, announcementLinesMap = [], varsAndTooltipsMap = [] } = entry;
    switch (true) {
      case name?.toLowerCase().includes(search?.toLowerCase()):
      case Object.keys(announcementLinesMap).some((lineKey) =>
        lineKey.toLowerCase().includes(search?.toLowerCase()),
      ):
      case Object.values(announcementLinesMap).some((line) =>
        line.toLowerCase().includes(search?.toLowerCase()),
      ):
      case Object.keys(varsAndTooltipsMap).some((varName) =>
        varName.toLowerCase().includes(search?.toLowerCase()),
      ):
        return true;
      default:
        return false;
    }
  };

  const errorMessage = !config_entries.length
    ? 'No configurable options detected! Please report this to NanoTrasen.'
    : 'No match. Refine your search.';

  const sorted = sortBy(
    filter(config_entries, (entry) => isEntryMatch(entry, search)),
    (entry) => entry.name,
  );
  return (
    <Window title="Automated Announcement System" width={500} height={280}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <LabeledList>
              <LabeledList.Item label="Search">
                <Input
                  fluid
                  placeholder="Name/Line/Var"
                  onInput={(event, value) => setSearch(value)}
                />
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
          <Stack.Item grow>
            {!sorted.length ? (
              <NoticeBox>{errorMessage}</NoticeBox>
            ) : (
              <Section fill scrollable>
                {sorted.map((entry, index) => (
                  <Section
                    key={entry.entryRef}
                    title={entry.name}
                    buttons={
                      <>
                        <Button
                          icon="info"
                          tooltip={
                            (entry.generalTooltip
                              ? entry.generalTooltip + '\n'
                              : '') +
                            Object.entries(entry.varsAndTooltipsMap)
                              .map(
                                ([varName, tooltip]) =>
                                  '%' + varName + ' ' + tooltip,
                              )
                              .join('\n')
                          }
                          tooltipPosition="left"
                        />
                        <Button
                          icon={entry.enabled ? 'power-off' : 'times'}
                          selected={entry.enabled}
                          disabled={!entry.modifiable}
                          tooltip={
                            !entry.modifiable
                              ? 'Editing disabled by CentCom!'
                              : undefined
                          }
                          onClick={() =>
                            act('Toggle', { entryRef: entry.entryRef })
                          }
                        >
                          {entry.enabled ? 'On' : 'Off'}
                        </Button>
                      </>
                    }
                  >
                    <Table>
                      {Object.entries(entry.announcementLinesMap).map(
                        ([lineKey, announcementLine]) => (
                          <Table.Row key={lineKey}>
                            <Table.Cell collapsing color="label">
                              {lineKey}:
                            </Table.Cell>
                            <Table.Cell>
                              <Input
                                key={entry.entryRef + lineKey}
                                fluid
                                value={announcementLine}
                                disabled={!entry.modifiable}
                                onChange={(e, value) =>
                                  act('Text', {
                                    entryRef: entry.entryRef,
                                    lineKey,
                                    newText: value,
                                  })
                                }
                              />
                            </Table.Cell>
                          </Table.Row>
                        ),
                      )}
                    </Table>
                  </Section>
                ))}
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
