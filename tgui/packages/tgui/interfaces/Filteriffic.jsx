import { map } from 'common/collections';
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  ColorBox,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
} from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';
import { numberOfDecimalDigits } from 'tgui-core/math';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const FilterIntegerEntry = (props) => {
  const { value, name, filterName } = props;
  const { act } = useBackend();
  return (
    <NumberInput
      value={value || 0}
      minValue={-500}
      maxValue={500}
      step={1}
      stepPixelSize={5}
      width="39px"
      onDrag={(value) =>
        act('modify_filter_value', {
          name: filterName,
          new_data: {
            [name]: value,
          },
        })
      }
    />
  );
};

const FilterFloatEntry = (props) => {
  const { value, name, filterName } = props;
  const { act } = useBackend();
  const [step, setStep] = useState(0.01);

  return (
    <>
      <NumberInput
        value={value || 0}
        minValue={-500}
        maxValue={500}
        stepPixelSize={4}
        step={step}
        format={(value) => toFixed(value, numberOfDecimalDigits(step))}
        width="80px"
        onDrag={(value) =>
          act('transition_filter_value', {
            name: filterName,
            new_data: {
              [name]: value,
            },
          })
        }
      />
      <Box inline ml={2} mr={1}>
        Step:
      </Box>
      <NumberInput
        value={step}
        step={0.001}
        format={(value) => toFixed(value, 4)}
        width="70px"
        onChange={(value) => setStep(value)}
      />
    </>
  );
};

const FilterTextEntry = (props) => {
  const { value, name, filterName } = props;
  const { act } = useBackend();

  return (
    <Input
      value={value}
      width="250px"
      onChange={(e, value) =>
        act('modify_filter_value', {
          name: filterName,
          new_data: {
            [name]: value,
          },
        })
      }
    />
  );
};

const FilterColorEntry = (props) => {
  const { value, filterName, name } = props;
  const { act } = useBackend();
  return (
    <>
      <Button
        icon="pencil-alt"
        onClick={() =>
          act('modify_color_value', {
            name: filterName,
          })
        }
      />
      <ColorBox color={value} mr={0.5} />
      <Input
        value={value}
        width="90px"
        onChange={(e, value) =>
          act('transition_filter_value', {
            name: filterName,
            new_data: {
              [name]: value,
            },
          })
        }
      />
    </>
  );
};

const FilterIconEntry = (props) => {
  const { value, filterName } = props;
  const { act } = useBackend();
  return (
    <>
      <Button
        icon="pencil-alt"
        onClick={() =>
          act('modify_icon_value', {
            name: filterName,
          })
        }
      />
      <Box inline ml={1}>
        {value}
      </Box>
    </>
  );
};

const FilterFlagsEntry = (props) => {
  const { name, value, filterName, filterType } = props;
  const { act, data } = useBackend();

  const filterInfo = data.filter_info;
  const flags = filterInfo[filterType]['flags'];
  return map(flags, (bitField, flagName) => (
    <Button.Checkbox
      checked={value & bitField}
      onClick={() =>
        act('modify_filter_value', {
          name: filterName,
          new_data: {
            [name]: value ^ bitField,
          },
        })
      }
      key={flagName}
    >
      {flagName}
    </Button.Checkbox>
  ));
};

const FilterDataEntry = (props) => {
  const { name, value, hasValue, filterName } = props;

  const filterEntryTypes = {
    int: <FilterIntegerEntry {...props} />,
    float: <FilterFloatEntry {...props} />,
    string: <FilterTextEntry {...props} />,
    color: <FilterColorEntry {...props} />,
    icon: <FilterIconEntry {...props} />,
    flags: <FilterFlagsEntry {...props} />,
  };

  const filterEntryMap = {
    x: 'float',
    y: 'float',
    icon: 'icon',
    render_source: 'string',
    flags: 'flags',
    size: 'float',
    color: 'color',
    offset: 'float',
    radius: 'float',
    falloff: 'float',
    density: 'int',
    threshold: 'float',
    factor: 'float',
    repeat: 'int',
  };

  return (
    <LabeledList.Item label={name}>
      {filterEntryTypes[filterEntryMap[name]] || 'Not Found (This is an error)'}{' '}
      {!hasValue && (
        <Box inline color="average">
          (Default)
        </Box>
      )}
    </LabeledList.Item>
  );
};

const FilterEntry = (props) => {
  const { act, data } = useBackend();
  const { name, filterDataEntry } = props;
  const { type, priority, ...restOfProps } = filterDataEntry;

  const filterDefaults = data['filter_info'];

  const targetFilterPossibleKeys = Object.keys(
    filterDefaults[type]['defaults'],
  );

  return (
    <Collapsible
      title={name + ' (' + type + ')'}
      buttons={
        <>
          <NumberInput
            value={priority}
            step={1}
            stepPixelSize={10}
            width="60px"
            onChange={(value) =>
              act('change_priority', {
                name: name,
                new_priority: value,
              })
            }
          />
          <Button.Input
            content="Rename"
            placeholder={name}
            onCommit={(e, new_name) =>
              act('rename_filter', {
                name: name,
                new_name: new_name,
              })
            }
            width="90px"
          />
          <Button.Confirm
            icon="minus"
            onClick={() => act('remove_filter', { name: name })}
          />
        </>
      }
    >
      <Section level={2}>
        <LabeledList>
          {targetFilterPossibleKeys.map((entryName) => {
            const defaults = filterDefaults[type]['defaults'];
            const value = restOfProps[entryName] || defaults[entryName];
            const hasValue = value !== defaults[entryName];
            return (
              <FilterDataEntry
                key={entryName}
                filterName={name}
                filterType={type}
                name={entryName}
                value={value}
                hasValue={hasValue}
              />
            );
          })}
        </LabeledList>
      </Section>
    </Collapsible>
  );
};

export const Filteriffic = (props) => {
  const { act, data } = useBackend();
  const name = data.target_name || 'Unknown Object';
  const filters = data.target_filter_data || {};
  const hasFilters = Object.keys(filters).length !== 0;
  const filterDefaults = data['filter_info'];
  const [massApplyPath, setMassApplyPath] = useState('');
  const [hiddenSecret, setHiddenSecret] = useState(false);

  return (
    <Window title="Filteriffic" width={500} height={500}>
      <Window.Content scrollable>
        <NoticeBox danger>
          DO NOT MESS WITH EXISTING FILTERS IF YOU DO NOT KNOW THE CONSEQUENCES.
          YOU HAVE BEEN WARNED.
        </NoticeBox>
        <Section
          title={
            hiddenSecret ? (
              <>
                <Box mr={0.5} inline>
                  MASS EDIT:
                </Box>
                <Input
                  value={massApplyPath}
                  width="100px"
                  onChange={(e, value) => setMassApplyPath(value)}
                />
                <Button.Confirm
                  content="Apply"
                  confirmContent="ARE YOU SURE?"
                  onClick={() => act('mass_apply', { path: massApplyPath })}
                />
              </>
            ) : (
              <Box inline onDoubleClick={() => setHiddenSecret(true)}>
                {name}
              </Box>
            )
          }
          buttons={
            <Dropdown
              icon="plus"
              displayText="Add Filter"
              noChevron
              options={Object.keys(filterDefaults)}
              onSelected={(value) =>
                act('add_filter', {
                  name: 'default',
                  priority: 10,
                  type: value,
                })
              }
            />
          }
        >
          {!hasFilters ? (
            <Box>No filters</Box>
          ) : (
            map(filters, (entry, key) => (
              <FilterEntry filterDataEntry={entry} name={key} key={key} />
            ))
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
