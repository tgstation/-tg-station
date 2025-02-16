import { Button, ColorBox, Section, Stack, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';
import { NTOSData } from '../layouts/NtosWindow';

export const NtosMain = (props) => {
  const { act, data } = useBackend<NTOSData>();
  const {
    alert_style,
    alert_color,
    alert_name,
    PC_device_theme,
    show_imprint,
    programs = [],
    has_light,
    light_on,
    comp_light_color,
    removable_media = [],
    login,
    proposed_login,
    pai,
  } = data;
  const filtered_programs = programs.filter(
    (program) => program.header_program,
  );

  return (
    <NtosWindow
      title={
        (PC_device_theme === 'syndicate' && 'Syndix Main Menu') ||
        'NtOS Main Menu'
      }
      width={400}
      height={500}
      z
    >
      <NtosWindow.Content scrollable>
        {Boolean(
          removable_media.length ||
            programs.some((program) => program.header_program),
        ) && (
          <Section>
            <Stack>
              {filtered_programs.map((app) => (
                <Stack.Item key={app.name}>
                  <Button
                    content={app.desc}
                    icon={app.icon}
                    onClick={() =>
                      act('PC_runprogram', {
                        name: app.name,
                      })
                    }
                  />
                </Stack.Item>
              ))}
              <Stack.Item right={0}>
                <Button
                  className={
                    alert_style == 2
                      ? 'alertIndicator alertBlink'
                      : 'alertIndicator'
                  }
                  textColor={alert_style == 0 ? alert_color : '#000000'}
                  backgroundColor={alert_style == 0 ? '#0000000' : alert_color}
                  tooltip="The current alert level. Indicator becomes more intense when there is a threat, moreso if your department is responsible for handling it."
                >
                  {alert_name}
                </Button>
              </Stack.Item>
            </Stack>
            <Stack>
              {removable_media.map((device) => (
                <Stack.Item key={device} mt={1}>
                  <Button
                    fluid
                    icon="eject"
                    content={device}
                    onClick={() => act('PC_Eject_Disk', { name: device })}
                    disabled={!device}
                  />
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        )}
        <Section
          title="Details"
          buttons={
            <>
              {!!has_light && (
                <>
                  <Button onClick={() => act('PC_light_color')}>
                    <ColorBox color={comp_light_color} />
                  </Button>
                  <Button
                    icon="lightbulb"
                    color={light_on ? 'good' : 'bad'}
                    selected={light_on}
                    onClick={() => act('PC_toggle_light')}
                  />
                </>
              )}
              <Button
                icon="eject"
                content="Eject ID"
                disabled={!proposed_login.IDInserted}
                onClick={() => act('PC_Eject_Disk', { name: 'ID' })}
              />
              {!!show_imprint && (
                <Button
                  icon="dna"
                  content="Imprint ID"
                  disabled={
                    !proposed_login.IDName ||
                    (proposed_login.IDName === login.IDName &&
                      proposed_login.IDJob === login.IDJob)
                  }
                  onClick={() => act('PC_Imprint_ID', { name: 'ID' })}
                />
              )}
            </>
          }
        >
          <Table>
            <Table.Row>
              ID Name:{' '}
              {show_imprint
                ? login.IDName +
                  ' ' +
                  (proposed_login.IDName
                    ? '(' + proposed_login.IDName + ')'
                    : '')
                : (proposed_login.IDName ?? '')}
            </Table.Row>
            <Table.Row>
              Assignment:{' '}
              {show_imprint
                ? login.IDJob +
                  ' ' +
                  (proposed_login.IDJob ? '(' + proposed_login.IDJob + ')' : '')
                : (proposed_login.IDJob ?? '')}
            </Table.Row>
          </Table>
        </Section>
        {!!pai && (
          <Section title="pAI">
            <Table>
              <Table.Row>
                <Table.Cell>
                  <Button
                    fluid
                    icon="eject"
                    color="transparent"
                    content="Eject pAI"
                    onClick={() =>
                      act('PC_Pai_Interact', {
                        option: 'eject',
                      })
                    }
                  />
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Button
                    fluid
                    icon="cat"
                    color="transparent"
                    content="Configure pAI"
                    onClick={() =>
                      act('PC_Pai_Interact', {
                        option: 'interact',
                      })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            </Table>
          </Section>
        )}
        <ProgramsTable />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const ProgramsTable = (props) => {
  const { act, data } = useBackend<NTOSData>();
  const { programs = [] } = data;
  // add the program filename to this list to have it excluded from the main menu program list table
  const filtered_programs = programs.filter(
    (program) => !program.header_program,
  );

  return (
    <Section title="Programs">
      <Table>
        {filtered_programs.map((program) => (
          <Table.Row key={program.name}>
            <Table.Cell>
              <Button
                fluid
                color={program.alert ? 'yellow' : 'transparent'}
                icon={program.icon}
                content={program.desc}
                onClick={() =>
                  act('PC_runprogram', {
                    name: program.name,
                  })
                }
              />
            </Table.Cell>
            <Table.Cell collapsing width="18px">
              {!!program.running && (
                <Button
                  color="transparent"
                  icon="times"
                  tooltip="Close program"
                  tooltipPosition="left"
                  onClick={() =>
                    act('PC_killprogram', {
                      name: program.name,
                    })
                  }
                />
              )}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
