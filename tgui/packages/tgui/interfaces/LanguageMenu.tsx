import {
  Button,
  DmIcon,
  Icon,
  Section,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Language = {
  name: string;
  desc: string;
  key: string;
  is_default: BooleanLike;
  can_speak?: BooleanLike;
  can_understand?: BooleanLike;
  icon: string;
  icon_state: string;
};

type Data = {
  is_living: BooleanLike;
  admin_mode?: BooleanLike;
  omnitongue?: BooleanLike;
  languages: Language[];
  unknown_languages?: Language[];
};

export const LanguageMenu = (props) => {
  const {
    act,
    data: {
      admin_mode,
      is_living,
      omnitongue,
      languages = [],
      unknown_languages = [],
    },
  } = useBackend<Data>();
  return (
    <Window title="Language Menu" width={700} height={600}>
      <Window.Content scrollable>
        <Section title="Known Languages">
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Understand</Table.Cell>
              <Table.Cell>Speak</Table.Cell>
              <Table.Cell>Key</Table.Cell>
              <Table.Cell>Description</Table.Cell>
            </Table.Row>
            {languages.map((language) => (
              <Table.Row key={language.name}>
                <Table.Cell verticalAlign="middle">
                  <Stack>
                    <Stack.Item>
                      <DmIcon
                        icon={language.icon}
                        icon_state={language.icon_state}
                      />
                    </Stack.Item>
                    <Stack.Item>{language.name}</Stack.Item>
                  </Stack>
                </Table.Cell>
                <Table.Cell textAlign="center">
                  <Tooltip
                    content={
                      language.can_understand
                        ? 'You can understand this language.'
                        : 'You cannot understand this language.'
                    }
                  >
                    <Icon
                      name="brain"
                      color={language.can_understand ? 'good' : 'bad'}
                    />
                  </Tooltip>
                </Table.Cell>
                <Table.Cell textAlign="center">
                  <Tooltip
                    content={
                      language.can_speak
                        ? 'You can speak this language.'
                        : 'You cannot speak this language.'
                    }
                  >
                    <Icon
                      name="comment"
                      color={language.can_speak ? 'good' : 'bad'}
                    />
                  </Tooltip>
                </Table.Cell>
                <Table.Cell textAlign="center">,{language.key}</Table.Cell>
                <Table.Cell p={0.5}>{language.desc}</Table.Cell>
                {!!is_living && (
                  <Table.Cell>
                    <Button
                      disabled={!language.can_speak}
                      selected={language.is_default}
                      onClick={() =>
                        act('select_default', {
                          language_name: language.name,
                        })
                      }
                    >
                      {language.is_default
                        ? 'Default Language'
                        : 'Select as Default'}
                    </Button>
                  </Table.Cell>
                )}
                {!!admin_mode && (
                  <Table.Cell>
                    <>
                      <Button
                        onClick={() =>
                          act('grant_language', {
                            language_name: language.name,
                          })
                        }
                      >
                        Grant
                      </Button>
                      <Button
                        onClick={() =>
                          act('remove_language', {
                            language_name: language.name,
                          })
                        }
                      >
                        Remove
                      </Button>
                    </>
                  </Table.Cell>
                )}
              </Table.Row>
            ))}
          </Table>
        </Section>
        {!!admin_mode && (
          <Section
            title="Unknown Languages"
            buttons={
              <Button
                selected={omnitongue}
                onClick={() => act('toggle_omnitongue')}
              >
                {'Omnitongue ' + (omnitongue ? 'Enabled' : 'Disabled')}
              </Button>
            }
          >
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Understand</Table.Cell>
                <Table.Cell>Speak</Table.Cell>
                <Table.Cell>Key</Table.Cell>
                <Table.Cell>Description</Table.Cell>
              </Table.Row>
              {unknown_languages.map((language) => (
                <Table.Row key={language.name}>
                  <Table.Cell verticalAlign="middle">
                    <Stack>
                      <Stack.Item>
                        <DmIcon
                          icon={language.icon}
                          icon_state={language.icon_state}
                        />
                      </Stack.Item>
                      <Stack.Item>{language.name}</Stack.Item>
                    </Stack>
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    <Tooltip
                      content={
                        language.can_understand
                          ? 'You can understand this language.'
                          : 'You cannot understand this language.'
                      }
                    >
                      <Icon
                        name="brain"
                        color={language.can_understand ? 'good' : 'bad'}
                      />
                    </Tooltip>
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    <Tooltip
                      content={
                        language.can_speak
                          ? 'You can speak this language.'
                          : 'You cannot speak this language.'
                      }
                    >
                      <Icon
                        name="comment"
                        color={language.can_speak ? 'good' : 'bad'}
                      />
                    </Tooltip>
                  </Table.Cell>
                  <Table.Cell textAlign="center">,{language.key}</Table.Cell>
                  <Table.Cell p={0.5}>{language.desc}</Table.Cell>
                  <Table.Cell verticalAlign="middle">
                    <Button
                      onClick={() =>
                        act('grant_language', {
                          language_name: language.name,
                        })
                      }
                    >
                      Grant
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
