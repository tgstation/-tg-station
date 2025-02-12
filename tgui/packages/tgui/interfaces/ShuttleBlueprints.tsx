import { ReactNode, useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Direction } from '../constants';
import { Window } from '../layouts';

type AreaData = { name: string; ref: string };

type VisualizationToggleProps = { visualizing: BooleanLike };

type ShuttleConstructionUnieuqData = {
  linkedShuttle: 0;
  tooManyShuttles: BooleanLike;
  onCustomShuttle: BooleanLike;
};

type ShuttleConfigurationUniqueData = {
  linkedShuttle: string;
  onShuttle: BooleanLike;
  inDefaultArea: BooleanLike;
  currentArea: AreaData;
  defaultApc: BooleanLike;
  apcInMergeRegion: BooleanLike;
  apcs: Record<string, BooleanLike>;
  neighboringAreas: Record<string, string>;
  idle: BooleanLike;
};

type ShuttleBlueprintsData = {
  shuttles?: Record<string, string>;
  visualizing: BooleanLike;
  onShuttleFrame: BooleanLike;
  masterExists: BooleanLike;
  isMaster: BooleanLike;
} & (ShuttleConstructionUnieuqData | ShuttleConfigurationUniqueData);

type DirectionPadProps = {
  title: string;
  tooltip?: ReactNode;
  enabledDirections: Direction;
  selectedDirection: Direction;
  onSelect: (direction: Direction) => void;
};

const directionData: [Direction, string][] = [
  [Direction.NORTH, 'up'],
  [Direction.SOUTH, 'down'],
  [Direction.EAST, 'right'],
  [Direction.WEST, 'left'],
];

const DirectionPad = (props: DirectionPadProps) => {
  const { title, tooltip, enabledDirections, selectedDirection, onSelect } =
    props;
  const [north, south, east, west] = directionData.map(
    ([direction, icon_suffix], i) => (
      <Stack.Item key={i}>
        <Button
          fluid
          m={0}
          icon={`arrow-${icon_suffix}`}
          selected={selectedDirection & direction}
          disabled={!(enabledDirections & direction)}
          onClick={() => onSelect(direction)}
        />
      </Stack.Item>
    ),
  );
  const titleNode = (
    <Box width="100%" textAlign="center">
      {title}
    </Box>
  );
  return (
    <Section
      fill
      title={
        tooltip ? <Tooltip content={tooltip}>{titleNode}</Tooltip> : titleNode
      }
    >
      <Stack fill vertical align="center" justify="center">
        {north}
        <Stack.Item>
          <Stack>
            {west}
            <Stack.Item width="1rem" mx={1} />
            {east}
          </Stack>
        </Stack.Item>
        {south}
      </Stack>
    </Section>
  );
};

const VisualizationToggle = (props: VisualizationToggleProps) => {
  const { visualizing } = props;
  const { act } = useBackend<ShuttleBlueprintsData>();
  return (
    <Tooltip
      content="Toggle a visualization of shuttle frames you can use to construct a shuttle.
                Red tiles indicate frame parts built in invalid areas,
                or parts of suitable areas that need frame parts built on them."
    >
      <Box inline>
        Visualization:
        <Button
          color="transparent"
          icon={visualizing ? 'toggle-on' : 'toggle-off'}
          onClick={() => act('toggleVisualization')}
        />
      </Box>
    </Tooltip>
  );
};

const ShuttleConstruction = () => {
  const [shuttleDirection, setShuttleDirection] = useState<Direction>(
    Direction.NORTH,
  );
  const { act, data } = useBackend<ShuttleBlueprintsData>();
  if (data.linkedShuttle !== 0) {
    throw new Error('type guard failure - linkedShuttle must be 0');
  }
  const {
    onShuttleFrame,
    visualizing,
    tooManyShuttles,
    onCustomShuttle,
    masterExists,
  } = data;
  return (
    <Stack justify="space-around">
      <Stack.Item grow>
        <DirectionPad
          title="Shuttle Direction"
          tooltip="This specifies the direction that the shuttle being built is facing."
          enabledDirections={Direction.ALL}
          selectedDirection={shuttleDirection}
          onSelect={(dir) => setShuttleDirection(dir)}
        />
      </Stack.Item>
      <Stack.Item>
        <Stack fill vertical align="end" justify="space-between">
          <Stack.Item>
            <VisualizationToggle visualizing={visualizing} />
          </Stack.Item>
          <Stack.Item>
            <Stack vertical>
              <Stack.Item>
                <Button.Confirm
                  disabled={!onShuttleFrame || tooManyShuttles}
                  tooltip={
                    tooManyShuttles
                      ? 'There are too many shuttles already.'
                      : onShuttleFrame
                        ? null
                        : 'You must be standing on a shuttle frame to do this.'
                  }
                  onClick={() =>
                    act('tryBuildShuttle', { dir: shuttleDirection })
                  }
                >
                  Build New Shuttle
                </Button.Confirm>
              </Stack.Item>
              <Stack.Item>
                <Button.Confirm
                  disabled={!onCustomShuttle || masterExists}
                  tooltip={
                    onCustomShuttle
                      ? masterExists
                        ? 'The master blueprint for this shuttle still exists. \
                          Whoever has it can copy it to this set of blueprints.'
                        : null
                      : 'You must be on a custom shuttle to do this.'
                  }
                  onClick={() => act('tryLinkShuttle')}
                >
                  Connect To Existing Shuttle
                </Button.Confirm>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const ShuttleConfiguration = () => {
  const [name, setName] = useState('');
  const [mergeArea = { name: '', ref: '' }, setMergeArea] =
    useState<AreaData>();
  const { act, data } = useBackend<ShuttleBlueprintsData>();
  if (data.linkedShuttle === 0) {
    throw new Error('type guard failure - linkedShuttle must be non-zero');
  }
  const {
    visualizing,
    onShuttleFrame,
    onShuttle,
    inDefaultArea,
    currentArea = { name: '', ref: '' },
    neighboringAreas = {},
    apcs = {},
    defaultApc,
    apcInMergeRegion,
    idle,
    isMaster,
  } = data;
  const { name: currentAreaName, ref: currentAreaRef } = currentArea;
  const { name: mergeAreaName, ref: mergeAreaRef } = mergeArea;
  const removalApcConflict = defaultApc && apcs[currentAreaRef];
  const mergeApcConflict = apcInMergeRegion && apcs[mergeAreaRef];
  return (
    <Stack fill vertical align="center" justify="space-around">
      <Stack.Item textAlign="center">
        <h2>Current Area:</h2>
        <h3>
          {onShuttle
            ? inDefaultArea
              ? 'Default Area'
              : currentAreaName
            : 'Not on Shuttle'}
        </h3>
      </Stack.Item>
      <Stack.Item>
        <Input
          fluid
          placeholder="New Area Name"
          onChange={(_, value) => setName(value)}
        />
        <Stack>
          <Stack.Item>
            <Button.Confirm
              disabled={!(onShuttle && inDefaultArea)}
              tooltip={
                onShuttle
                  ? inDefaultArea
                    ? null
                    : 'You can only create a new area from the default area.'
                  : 'You must be on the linked shuttle to do this.'
              }
              onClick={() => act('createNewArea', { name: name })}
            >
              Create New Area
            </Button.Confirm>
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              disabled={!onShuttle || inDefaultArea}
              tooltip={
                onShuttle
                  ? inDefaultArea
                    ? 'You cannot rename the default area.'
                    : null
                  : 'You must be on the linked shuttle to do this.'
              }
              onClick={() => act('renameArea', { name: name })}
            >
              Rename Current Area
            </Button.Confirm>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item width="100%">
        <Stack fill justify="center">
          <Stack.Item>
            <Dropdown
              placeholder="Select Area"
              options={Object.entries(neighboringAreas).map(([ref, name]) => {
                return {
                  displayText: name,
                  value: ref,
                };
              })}
              selected={mergeAreaName}
              onSelected={(value) =>
                setMergeArea({ name: neighboringAreas[value], ref: value })
              }
            />
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              disabled={
                !(onShuttle && inDefaultArea && mergeArea) || mergeApcConflict
              }
              tooltip={
                'Expand the selected area with the connected section of the default area.' +
                (onShuttle
                  ? mergeArea
                    ? inDefaultArea
                      ? mergeApcConflict
                        ? '\nBoth the selected area and the region that it would expand into have APCs. You must remove one first.'
                        : ''
                      : '\nYou can only expand the selected area into the default area.'
                    : ''
                  : '\nYou must be on the linked shuttle to do this.')
              }
              onClick={() => act('mergeIntoArea', { area: mergeAreaRef })}
            >
              Expand Area
            </Button.Confirm>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack>
          <Stack.Item>
            <Button.Confirm
              disabled={!(idle && onShuttleFrame)}
              tooltip={
                'Expand the linked shuttle with an incomplete shuttle frame.' +
                (idle
                  ? onShuttleFrame
                    ? ''
                    : '\nYou must be on an incomplete shuttle frame to do this.'
                  : '\nThe shuttle must be idle to do this.')
              }
              onClick={() => act('expandWithFrame')}
            >
              Expand With Shuttle Frame
            </Button.Confirm>
          </Stack.Item>
          <Stack.Item>
            <VisualizationToggle visualizing={visualizing} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Button.Confirm
          disabled={!onShuttle || inDefaultArea || removalApcConflict}
          tooltip={
            'Merge the current area into the default area.' +
            (onShuttle
              ? inDefaultArea
                ? '\nYou are already in the default area.'
                : removalApcConflict
                  ? '\nBoth the current and default areas have APCs. You must remove one first.'
                  : ''
              : '\nYou must be on the linked shuttle to do this.')
          }
          onClick={() => act('releaseArea')}
        >
          Remove Area
        </Button.Confirm>
      </Stack.Item>
      <Stack.Item>
        <Button.Confirm
          disabled={!idle || !isMaster}
          tooltip={
            'Remove all empty space from the shuttle.' + isMaster
              ? idle
                ? '\nThis will delete any areas left without any space, \
              and will decommission the shuttle entirely if there is nothing left of it.'
                : '\nThe shuttle must be idle to do this.'
              : '\nOnly the master blueprint can do this.'
          }
          onClick={() => act('cleanupEmptyTurfs')}
        >
          Clean Up Empty Space
        </Button.Confirm>
      </Stack.Item>
    </Stack>
  );
};

export const ShuttleBlueprints = (props) => {
  const { act, data } = useBackend<ShuttleBlueprintsData>();
  const { linkedShuttle, shuttles, masterExists, isMaster } = data;
  return (
    <Window width={450} height={340}>
      <Window.Content>
        <Section
          fill
          buttons={
            <>
              {shuttles && (
                <Dropdown
                  options={[
                    { displayText: 'None', value: 0 },
                    ...Object.entries(shuttles).map(
                      ([ref, name]: [string, string]) => {
                        return { displayText: name, value: ref };
                      },
                    ),
                  ]}
                  selected={linkedShuttle ? shuttles[linkedShuttle] : 'None'}
                  onSelected={(value) => {
                    if (value === 0) {
                      act('unsetShuttle');
                    } else {
                      act('switchShuttle', { ref: value });
                    }
                  }}
                />
              )}
              {!!linkedShuttle && !masterExists && !isMaster && (
                <Button.Confirm onClick={() => act('promoteToMaster')}>
                  Promote To Master Blueprint
                </Button.Confirm>
              )}
            </>
          }
        >
          {linkedShuttle ? <ShuttleConfiguration /> : <ShuttleConstruction />}
        </Section>
      </Window.Content>
    </Window>
  );
};
