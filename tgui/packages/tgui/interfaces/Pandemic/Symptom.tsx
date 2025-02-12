import {
  Collapsible,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { getColor } from './helpers';
import { Threshold } from './types';

/**
 * Similar to the virus info display.
 * Returns info about symptoms as collapsibles.
 */
export const SymptomDisplay = (props) => {
  const { symptoms = [] } = props;
  if (!symptoms?.length) {
    return <NoticeBox>No symptoms detected.</NoticeBox>;
  }

  return (
    <Section fill title="Symptoms">
      {symptoms.map((symptom) => {
        const { name, desc, threshold_desc } = symptom;
        return (
          <Collapsible key={name} title={name}>
            <Stack fill>
              <Stack.Item grow={3}>
                {desc}
                <Thresholds thresholds={threshold_desc} />
              </Stack.Item>
              <Stack.Divider />
              <Stack.Item grow={1}>
                <Traits symptom={symptom} />
              </Stack.Item>
            </Stack>
          </Collapsible>
        );
      })}
    </Section>
  );
};

/** Displays threshold data */
const Thresholds = (props) => {
  const { thresholds = [] } = props;
  let convertedThresholds = Object.entries<Threshold>(thresholds);

  return (
    <Section mt={1} title="Thresholds">
      {!convertedThresholds.length ? (
        <NoticeBox>None</NoticeBox>
      ) : (
        <LabeledList>
          {convertedThresholds.map(([label, descr], index) => {
            return (
              <LabeledList.Item key={index} label={label}>
                {String(descr)}
              </LabeledList.Item>
            );
          })}
        </LabeledList>
      )}
    </Section>
  );
};

/** Displays the numerical trait modifiers for a virus symptom */
const Traits = (props) => {
  const {
    symptom: { level, resistance, stage_speed, stealth, transmission },
  } = props;

  return (
    <Section title="Modifiers">
      <LabeledList>
        <Tooltip content="Rarity of the symptom.">
          <LabeledList.Item color={getColor(level)} label="Level">
            {level}
          </LabeledList.Item>
        </Tooltip>
        <Tooltip content="Decides the cure complexity.">
          <LabeledList.Item color={getColor(resistance)} label="Resistance">
            {resistance}
          </LabeledList.Item>
        </Tooltip>
        <Tooltip content="Symptomic progression.">
          <LabeledList.Item color={getColor(stage_speed)} label="Stage Speed">
            {stage_speed}
          </LabeledList.Item>
        </Tooltip>
        <Tooltip content="Detection difficulty from medical equipment.">
          <LabeledList.Item color={getColor(stealth)} label="Stealth">
            {stealth}
          </LabeledList.Item>
        </Tooltip>
        <Tooltip content="Decides the spread type.">
          <LabeledList.Item color={getColor(transmission)} label="Transmission">
            {transmission}
          </LabeledList.Item>
        </Tooltip>
      </LabeledList>
    </Section>
  );
};
